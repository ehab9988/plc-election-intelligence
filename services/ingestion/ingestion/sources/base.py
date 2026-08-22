"""Source adapter contract (section 8 SourceRegistry / commercial licensing
requirement). Every adapter declares how it is legally allowed to fetch
content, so the pipeline can refuse to run an adapter that isn't
licensed/permitted for its ingestion_method.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class RawDocument:
    source_name: str
    ingestion_method: str  # rss | api | licensed_api | admin_entered | pdf_import
    canonical_url: str
    headline: str
    author: str | None
    published_at: datetime
    full_text: str  # adapter-local only; NEVER persisted verbatim past the
    # permitted-snippet extraction step (section 8) — see pipeline.py.
    language: str


class SourceAdapter(Protocol):
    """Implemented per source. `respects_licensing` must be True before
    the pipeline will call `fetch()` — see docs/SOURCE_LICENSING.md."""

    name: str
    ingestion_method: str
    respects_licensing: bool

    def fetch(self) -> list[RawDocument]: ...
