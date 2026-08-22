"""Reference RSS adapter — the ingestion method most sources permit
without a separate license (section 8 Tier 3/4). Uses `feedparser`
(not imported at module load so this file stays importable without the
dependency installed, matching this repo's "written but not executed"
state — see README)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime

from .base import RawDocument


@dataclass
class RssSourceAdapter:
    name: str
    feed_url: str
    language: str
    respects_licensing: bool = True
    ingestion_method: str = "rss"

    def fetch(self) -> list[RawDocument]:
        import feedparser  # local import: optional dependency

        parsed = feedparser.parse(self.feed_url)
        documents: list[RawDocument] = []
        for entry in parsed.entries:
            published = getattr(entry, "published_parsed", None)
            published_at = (
                datetime(*published[:6], tzinfo=UTC) if published else datetime.now(UTC)
            )
            documents.append(
                RawDocument(
                    source_name=self.name,
                    ingestion_method=self.ingestion_method,
                    canonical_url=entry.get("link", ""),
                    headline=entry.get("title", ""),
                    author=entry.get("author"),
                    published_at=published_at,
                    full_text=entry.get("summary", ""),
                    language=self.language,
                )
            )
        return documents
