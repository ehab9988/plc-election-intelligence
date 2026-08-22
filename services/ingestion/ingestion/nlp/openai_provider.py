"""OpenAI-compatible PoliticalNlpProvider (section 54 "no vendor lock-in").

Mirrors anthropic_provider.py's extraction contract exactly (same schema,
same system prompt) so swapping `NLP_PROVIDER=openai_compatible` for
`anthropic_compatible` in .env changes nothing else in the pipeline.
Works against the real OpenAI API or any OpenAI-API-compatible endpoint
(set `base_url` for a self-hosted/alternate provider).

Setup: `pip install openai`, then set `OPENAI_API_KEY` (see .env.example).
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass

from .anthropic_provider import EXTRACTION_SCHEMA, EXTRACTION_SYSTEM_PROMPT
from .provider import ExtractionResult

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "gpt-4o-mini"


@dataclass
class OpenAiNlpProvider:
    api_key: str | None = None
    base_url: str | None = None
    model: str = DEFAULT_MODEL

    def __post_init__(self) -> None:
        import openai  # local import: optional dependency, not required unless this provider is selected

        self._openai = openai
        kwargs = {}
        if self.api_key:
            kwargs["api_key"] = self.api_key
        if self.base_url:
            kwargs["base_url"] = self.base_url
        self._client = openai.OpenAI(**kwargs)

    def extract(self, text: str, language: str) -> ExtractionResult:
        openai = self._openai
        try:
            response = self._client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": EXTRACTION_SYSTEM_PROMPT},
                    {"role": "user", "content": f"Article language: {language}\n\nArticle text:\n{text}"},
                ],
                response_format={
                    "type": "json_schema",
                    "json_schema": {"name": "political_extraction", "schema": EXTRACTION_SCHEMA, "strict": True},
                },
            )
        except openai.AuthenticationError:
            logger.error("OpenAI NLP provider: authentication failed — check OPENAI_API_KEY.")
            return ExtractionResult()
        except openai.RateLimitError as exc:
            logger.warning("OpenAI NLP provider: rate limited (%s) — skipping this article this run.", exc)
            return ExtractionResult()
        except openai.APIStatusError as exc:
            logger.error("OpenAI NLP provider: API error %s: %s", exc.status_code, exc.message)
            return ExtractionResult()
        except openai.APIConnectionError:
            logger.error("OpenAI NLP provider: network error reaching the OpenAI API.")
            return ExtractionResult()

        content = response.choices[0].message.content
        if content is None:
            logger.error("OpenAI NLP provider: response had no content despite response_format.")
            return ExtractionResult()

        try:
            data = json.loads(content)
        except json.JSONDecodeError:
            logger.error("OpenAI NLP provider: response content was not valid JSON despite response_format.")
            return ExtractionResult()

        return ExtractionResult(
            entities=data.get("entities", []),
            events=data.get("events", []),
            claims=data.get("claims", []),
            relationships=data.get("relationships", []),
            dates=data.get("dates", []),
            confidence=float(data.get("confidence", 0.0)),
            evidence=data.get("evidence", []),
        )
