"""The actual ingestion/forecast/coalition-signal logic, as plain
functions with no Celery/Redis dependency.

Two callers use these:
  - tasks.py: thin @shared_task wrappers, for a deployment that runs a
    real Celery worker + beat process on a server (docs/DEPLOYMENT.md).
  - scripts/run_ingestion_cycle.py: a direct CLI invocation, for
    deployments with no server at all — e.g. a GitHub Actions scheduled
    workflow (docs/FREE_TIER_DEPLOYMENT.md), which spins up a fresh
    ephemeral runner per invocation and cannot host a persistent broker
    or worker process anyway.

Cross-imports services/api's SQLAlchemy models and forecast runner
directly (same database, same monorepo) — see docs/DEPLOYMENT.md.
"""

from __future__ import annotations

import logging

from sqlalchemy import select

from app.config import settings
from app.db import SessionLocal
from app.models import (
    Article,
    ArticleEntity,
    CoalitionEvidence,
    Election,
    NewsSource,
    Party,
    PartyAlias,
    Poll,
    Source,
)
from app.models.enums import SourceTier, SourceType, VerificationConfidence
from app.services.forecast_runner import run_and_persist_forecast

from .dedup import is_probable_duplicate
from .nlp.factory import build_nlp_provider
from .nlp.provider import ExtractionResult
from .pipeline import requires_human_review
from .sources.rss_adapter import RssSourceAdapter

logger = logging.getLogger(__name__)


def _nlp_provider():
    return build_nlp_provider(
        settings.nlp_provider,
        anthropic_api_key=settings.anthropic_api_key,
        anthropic_model=settings.anthropic_model,
        openai_api_key=settings.openai_api_key,
        openai_base_url=settings.openai_base_url,
        openai_model=settings.openai_model,
    )


def _resolve_party_mention(db, mention_text: str) -> Party | None:
    """Best-effort entity resolution: exact/alias match against known
    party names. NOT a full implementation of spec section 10's entity
    resolution system (fuzzy/transliteration matching, canonical-id
    merge review) — a real deployment should replace this with a proper
    resolver before trusting auto-created CoalitionEvidence rows at
    scale. Returns None (and the caller skips) rather than guessing."""
    needle = mention_text.strip().lower()
    if not needle:
        return None
    party = db.scalar(
        select(Party).where(
            (Party.name_en.ilike(f"%{needle}%"))
            | (Party.name_ar == mention_text)
            | (Party.abbreviation.ilike(needle))
        )
    )
    if party:
        return party
    alias = db.scalar(select(PartyAlias).where(PartyAlias.alias.ilike(needle)))
    return db.get(Party, alias.party_id) if alias else None


def _store_documents(db, news_source_id, documents, nlp, recent_articles: list, stats: dict) -> None:
    """Shared dedupe -> NLP-extraction -> storage loop, used by both
    ingest_all_sources() (RSS, one NewsSource per feed) and
    discover_news_via_ai() (OpenAI web search, one synthetic NewsSource
    for everything it finds — see _get_or_create_ai_news_source)."""
    for doc in documents:
        if any(
            is_probable_duplicate(doc.canonical_url, doc.headline, a.canonical_url, a.headline, doc.language)
            for a in recent_articles
        ):
            stats["duplicates"] += 1
            continue

        extraction: ExtractionResult = nlp.extract(doc.full_text, doc.language)

        article = Article(
            news_source_id=news_source_id,
            headline=doc.headline,
            author=doc.author,
            published_at=doc.published_at,
            canonical_url=doc.canonical_url,
            permitted_snippet=doc.full_text[:400] if doc.full_text else None,
            language=doc.language,
            nlp_confidence=extraction.confidence,
            human_reviewed=False,
        )
        db.add(article)
        db.flush()
        recent_articles.append(article)
        stats["stored"] += 1

        for entity in extraction.entities:
            # Only "party" mentions are resolvable in this reference
            # implementation (_resolve_party_mention). Person/
            # electoral_list resolution needs a real entity-resolution
            # system (spec section 10) this build does not include —
            # skip rather than store a row pointing entity_id at the
            # wrong table.
            if entity.get("entity_type") != "party":
                continue
            resolved = _resolve_party_mention(db, entity.get("mention_text", ""))
            if resolved is None:
                continue
            db.add(
                ArticleEntity(
                    article_id=article.id,
                    entity_type="party",
                    entity_id=resolved.id,
                    mention_text=entity.get("mention_text", ""),
                    extraction_confidence=float(entity.get("confidence", 0.0)),
                )
            )

        if any(
            requires_human_review(extraction, event.get("category")) for event in extraction.events
        ) or not extraction.events:
            stats["flagged_for_review"] += 1


def ingest_all_sources() -> dict:
    """Fetches configured RSS sources, dedupes, stores permitted metadata
    only (never full article text — section 8 licensing rule), and runs
    NLP extraction. High-impact extractions are flagged for review rather
    than silently trusted (section 53)."""
    db = SessionLocal()
    stats = {"sources": 0, "fetched": 0, "duplicates": 0, "stored": 0, "flagged_for_review": 0}
    try:
        news_sources = db.scalars(
            select(NewsSource).where(NewsSource.active.is_(True), NewsSource.ingestion_method == "rss")
        ).all()
        stats["sources"] = len(news_sources)
        nlp = _nlp_provider()

        recent_articles = db.scalars(
            select(Article).order_by(Article.published_at.desc()).limit(500)
        ).all()

        for news_source in news_sources:
            if not news_source.feed_url:
                continue
            adapter = RssSourceAdapter(
                name=news_source.name, feed_url=news_source.feed_url, language=news_source.language
            )
            try:
                documents = adapter.fetch()
            except Exception:
                logger.exception("Failed to fetch RSS source %s; leaving prior data untouched.", news_source.name)
                continue
            stats["fetched"] += len(documents)
            _store_documents(db, news_source.id, documents, nlp, recent_articles, stats)

        db.commit()
    finally:
        db.close()
    return stats


def _get_or_create_ai_news_source(db) -> NewsSource:
    existing = db.scalar(select(NewsSource).where(NewsSource.ingestion_method == "openai_search"))
    if existing:
        return existing
    source = NewsSource(
        name="OpenAI web search",
        language="en",
        ingestion_method="openai_search",
        feed_url=None,
        respects_robots_txt=True,
        license_notes=(
            "Discovered via the OpenAI web_search tool, not a curated feed — "
            "see sources/openai_search_adapter.py."
        ),
        active=True,
    )
    db.add(source)
    db.flush()
    return source


def discover_news_via_ai() -> dict:
    """Uses OpenAI's web_search tool to find and ingest recent Palestinian
    election news with no per-outlet feed_url configured — only
    OPENAI_API_KEY is required. See sources/openai_search_adapter.py.
    Reuses the exact same dedupe -> NLP-extraction -> storage logic
    ingest_all_sources() uses for RSS sources (_store_documents)."""
    if not settings.openai_api_key:
        return {"status": "skipped_no_api_key"}

    from .sources.openai_search_adapter import OpenAiSearchNewsAdapter

    db = SessionLocal()
    stats = {"fetched": 0, "duplicates": 0, "stored": 0, "flagged_for_review": 0}
    try:
        news_source = _get_or_create_ai_news_source(db)
        nlp = _nlp_provider()
        recent_articles = db.scalars(select(Article).order_by(Article.published_at.desc()).limit(500)).all()

        try:
            documents = OpenAiSearchNewsAdapter(api_key=settings.openai_api_key, model=settings.openai_model).fetch()
        except Exception:
            logger.exception("OpenAI news discovery failed; leaving prior data untouched.")
            return {"status": "search_failed"}
        stats["fetched"] = len(documents)
        _store_documents(db, news_source.id, documents, nlp, recent_articles, stats)

        db.commit()
    finally:
        db.close()
    return stats


def discover_polls_via_ai() -> dict:
    """Uses OpenAI's web_search tool to find recently published polls and
    drafts them as UNVERIFIED Poll rows for analyst review — see
    poll_discovery.py's module docstring for why this can never move the
    published forecast on its own."""
    if not settings.openai_api_key:
        return {"status": "skipped_no_api_key"}

    from .poll_discovery import draft_polls_from_ai_discovery

    db = SessionLocal()
    try:
        election = db.scalar(select(Election).where(Election.is_current.is_(True)))
        if election is None:
            return {"status": "no_current_election"}
        return draft_polls_from_ai_discovery(db, election.id, settings.openai_api_key, settings.openai_model)
    finally:
        db.close()


def maybe_recompute_forecast() -> dict:
    """Re-runs the forecast for the current election if a manually-verified
    poll exists. Never triggers on unverified poll imports or unreviewed
    NLP extractions — only on data an analyst (or an authoritative source)
    has confirmed (section 53, 60)."""
    db = SessionLocal()
    try:
        election = db.scalar(select(Election).where(Election.is_current.is_(True)))
        if election is None:
            return {"status": "no_current_election"}

        latest_verified_poll = db.scalar(
            select(Poll)
            .where(Poll.election_id == election.id, Poll.manually_verified.is_(True))
            .order_by(Poll.import_timestamp.desc())
        )
        if latest_verified_poll is None:
            return {"status": "no_verified_polls_yet"}

        run = run_and_persist_forecast(
            db,
            election_id=election.id,
            change_summary=(
                f"Automatic scheduled recompute triggered by the ingestion cycle "
                f"(most recent verified poll: {latest_verified_poll.fieldwork_end})."
            ),
        )
        return {"status": "recomputed", "run_id": str(run.id)}
    finally:
        db.close()


def scan_coalition_signals() -> dict:
    """Scans recently-ingested articles' NLP extractions for
    coalition_with and joint_list_with relationships and drafts
    CoalitionEvidence rows for analyst review. Never marks a draft as
    verified automatically — coalition/alliance claims are exactly the
    kind of high-impact change spec section 53 requires human review
    for, and "will these two parties run on one list" is deliberately
    never scored as a probability — see docs/COALITION_MODEL.md. It's
    surfaced only as this same kind of sourced, confidence-tagged
    evidence, with implies_joint_list distinguishing it from a broader
    coalition_with claim."""
    db = SessionLocal()
    stats = {"drafted": 0, "skipped_unresolved": 0}
    try:
        # In this reference implementation, relationship extraction is
        # re-run against recent articles' stored snippets rather than
        # persisted separately (article_entities only stores entity
        # mentions, not relationships) — a production system should add
        # a dedicated `article_relationships` table instead of
        # re-extracting here. Documented gap, not hidden.
        recent_articles = db.scalars(
            select(Article).order_by(Article.published_at.desc()).limit(50)
        ).all()
        nlp = _nlp_provider()

        for article in recent_articles:
            if not article.permitted_snippet:
                continue
            extraction = nlp.extract(article.permitted_snippet, article.language)
            for rel in extraction.relationships:
                rel_type = rel.get("relationship_type")
                if rel_type not in ("coalition_with", "joint_list_with"):
                    continue
                party_a = _resolve_party_mention(db, rel.get("entity_a", ""))
                party_b = _resolve_party_mention(db, rel.get("entity_b", ""))
                if party_a is None or party_b is None:
                    stats["skipped_unresolved"] += 1
                    continue

                already_exists = db.scalar(
                    select(CoalitionEvidence).where(
                        CoalitionEvidence.party_a_id == party_a.id,
                        CoalitionEvidence.party_b_id == party_b.id,
                        CoalitionEvidence.source_id == article.news_source_id,
                    )
                )
                if already_exists:
                    continue

                source = db.get(Source, article.news_source_id) or Source(
                    name=f"Ingested source for article {article.id}",
                    source_type=SourceType.NEWS_ORGANIZATION,
                    tier=SourceTier.TIER_3_NEWS,
                )
                if source.id is None:
                    db.add(source)
                    db.flush()

                db.add(
                    CoalitionEvidence(
                        party_a_id=party_a.id,
                        party_b_id=party_b.id,
                        evidence_type="supporting",
                        implies_joint_list=rel_type == "joint_list_with",
                        statement_summary=article.headline,
                        statement_date=article.published_at.date(),
                        source_id=source.id,
                        confidence=VerificationConfidence.LOW,  # auto-drafted; awaits analyst review
                    )
                )
                stats["drafted"] += 1

        db.commit()
    finally:
        db.close()
    return stats
