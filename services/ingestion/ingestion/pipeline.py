"""Orchestrates: fetch -> normalize -> dedupe -> classify -> extract ->
confidence score -> human-review queue -> database (section 9).

This is the reference wiring, not a production scheduler — in a real
deployment this would be invoked by a Celery/RQ/Dramatiq periodic task
(section 6) per configured NewsSource.
"""

from __future__ import annotations

from dataclasses import dataclass

from .dedup import is_probable_duplicate
from .nlp.provider import ExtractionResult, PoliticalNlpProvider
from .sources.base import RawDocument, SourceAdapter

HIGH_IMPACT_CATEGORIES = {
    "candidate_withdrawal",
    "party_alliance",
    "list_registration",
    "legal_change",
}


@dataclass
class PipelineResult:
    documents_fetched: int
    duplicates_skipped: int
    accepted_for_review: list[RawDocument]
    extractions: dict[str, ExtractionResult]


def run_pipeline(adapters: list[SourceAdapter], nlp: PoliticalNlpProvider) -> PipelineResult:
    all_docs: list[RawDocument] = []
    for adapter in adapters:
        if not adapter.respects_licensing:
            # Refuse to run an adapter that hasn't been marked as
            # licensed/permitted — see docs/SOURCE_LICENSING.md.
            continue
        all_docs.extend(adapter.fetch())

    deduped: list[RawDocument] = []
    duplicates = 0
    for doc in all_docs:
        if any(
            is_probable_duplicate(doc.canonical_url, doc.headline, kept.canonical_url, kept.headline, doc.language)
            for kept in deduped
        ):
            duplicates += 1
            continue
        deduped.append(doc)

    extractions: dict[str, ExtractionResult] = {}
    for doc in deduped:
        extractions[doc.canonical_url] = nlp.extract(doc.full_text, doc.language)

    return PipelineResult(
        documents_fetched=len(all_docs),
        duplicates_skipped=duplicates,
        accepted_for_review=deduped,
        extractions=extractions,
    )


def requires_human_review(extraction: ExtractionResult, category: str | None) -> bool:
    """High-impact changes require either an authoritative source or human
    analyst approval before being committed as verified (section 53)."""
    if category in HIGH_IMPACT_CATEGORIES:
        return True
    return extraction.confidence < 0.6
