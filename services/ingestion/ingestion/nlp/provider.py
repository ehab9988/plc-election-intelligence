"""PoliticalNlpProvider interface (section 54) — the app must work even if
the LLM/NLP backend is swapped. Extraction output is always the strict
JSON shape from section 53: entities/events/claims/relationships/dates/
confidence/evidence. The provider is an EXTRACTION ASSISTANT, never a
factual authority (section 53) — see pipeline.py for how output here
becomes (or doesn't become) a verified fact.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol


@dataclass
class ExtractionResult:
    entities: list[dict] = field(default_factory=list)
    events: list[dict] = field(default_factory=list)
    claims: list[dict] = field(default_factory=list)
    relationships: list[dict] = field(default_factory=list)
    dates: list[dict] = field(default_factory=list)
    confidence: float = 0.0
    evidence: list[str] = field(default_factory=list)


class PoliticalNlpProvider(Protocol):
    def extract(self, text: str, language: str) -> ExtractionResult: ...
