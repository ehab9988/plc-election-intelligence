"""OpenAI web-search-based news discovery — an alternative to
rss_adapter.py's per-source `feed_url` configuration: instead of curating
a list of RSS feeds, this asks an OpenAI model with the built-in
`web_search` tool to find recent Palestinian election news itself, then
returns the same `RawDocument` shape `rss_adapter.py` does so it flows
through the identical dedupe -> NLP-extraction -> storage pipeline in
jobs.py (`_ingest_documents`) unchanged.

Only `OPENAI_API_KEY` is required — no per-source URL to configure.

Could not be exercised against a real OpenAI account in this development
sandbox (no network egress, no API key available here) — see README
"What could not be verified". Verify the exact `web_search` tool name and
Responses API output shape against current OpenAI docs before relying on
this in production; that tool's naming/schema has changed across SDK
versions and this could not be checked against a live account here.

Setup: `pip install openai`, then set `OPENAI_API_KEY`.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone

from .base import RawDocument

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "gpt-4o-mini"

DEFAULT_QUERIES = [
    "Palestinian Legislative Council election 2026 news",
    "PLC 2026 election Fatah Hamas coalition alliance",
    "Palestinian election candidate list registration 2026",
]

_RESULT_SCHEMA = {
    "type": "object",
    "properties": {
        "articles": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "headline": {"type": "string"},
                    "canonical_url": {"type": "string"},
                    "published_date": {
                        "type": ["string", "null"],
                        "description": "ISO 8601 date if known, else null",
                    },
                    "summary": {
                        "type": "string",
                        "description": "A short, factual summary of what the article reports — not commentary.",
                    },
                    "language": {"type": "string", "description": "e.g. 'en' or 'ar'"},
                },
                "required": ["headline", "canonical_url", "summary", "language"],
                "additionalProperties": False,
            },
        },
    },
    "required": ["articles"],
    "additionalProperties": False,
}

_SYSTEM_PROMPT = """\
You are a news-discovery assistant for a Palestinian election intelligence \
platform. Use web search to find recent, real news articles about the \
topic given. Only include articles you actually found via search — never \
invent a headline, URL, or summary. Every canonical_url must be a real \
URL returned by the search tool, not a guess. Summarize factually; do not \
add opinion or speculation beyond what the article itself states.
"""


@dataclass
class OpenAiSearchNewsAdapter:
    """Implements the same `fetch() -> list[RawDocument]` contract as
    `RssSourceAdapter` — see `sources/base.py`'s `SourceAdapter` protocol."""

    api_key: str | None = None
    model: str = DEFAULT_MODEL
    queries: list[str] = field(default_factory=lambda: list(DEFAULT_QUERIES))
    name: str = "OpenAI web search"
    ingestion_method: str = "api"
    respects_licensing: bool = True

    def __post_init__(self) -> None:
        import openai  # local import: optional dependency, not required unless this adapter is used

        self._openai = openai
        self._client = openai.OpenAI(api_key=self.api_key) if self.api_key else openai.OpenAI()

    def fetch(self) -> list[RawDocument]:
        documents: list[RawDocument] = []
        for query in self.queries:
            documents.extend(self._search(query))
        return documents

    def _search(self, query: str) -> list[RawDocument]:
        try:
            response = self._client.responses.create(
                model=self.model,
                tools=[{"type": "web_search"}],
                input=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": f"Find recent news for: {query}"},
                ],
                text={
                    "format": {
                        "type": "json_schema",
                        "name": "news_search_results",
                        "schema": _RESULT_SCHEMA,
                        "strict": True,
                    }
                },
            )
        except self._openai.AuthenticationError:
            logger.error("OpenAI search adapter: authentication failed — check OPENAI_API_KEY.")
            return []
        except self._openai.RateLimitError as exc:
            logger.warning("OpenAI search adapter: rate limited (%s) — skipping query %r this run.", exc, query)
            return []
        except Exception:
            logger.exception("OpenAI search adapter: search failed for query %r.", query)
            return []

        try:
            payload = json.loads(response.output_text)
        except (AttributeError, json.JSONDecodeError):
            logger.error("OpenAI search adapter: could not parse structured output for query %r.", query)
            return []

        documents: list[RawDocument] = []
        for item in payload.get("articles", []):
            url = item.get("canonical_url", "")
            if not url:
                continue
            published_at = datetime.now(timezone.utc)
            raw_date = item.get("published_date")
            if raw_date:
                try:
                    published_at = datetime.fromisoformat(raw_date.replace("Z", "+00:00"))
                except ValueError:
                    pass
            documents.append(
                RawDocument(
                    source_name=self.name,
                    ingestion_method=self.ingestion_method,
                    canonical_url=url,
                    headline=item.get("headline", ""),
                    author=None,
                    published_at=published_at,
                    full_text=item.get("summary", ""),
                    language=item.get("language", "en"),
                )
            )
        return documents
