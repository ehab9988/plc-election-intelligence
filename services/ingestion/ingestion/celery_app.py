"""Celery app + beat schedule for 24/7 ingestion and forecast re-computation.

This is what actually makes the platform "dynamic": deployed and running,
it (a) polls configured news sources on a fixed cadence, (b) extracts
structured signals via the configured PoliticalNlpProvider, (c) drafts
CoalitionEvidence rows from detected alliance/dispute language for
analyst review, and (d) re-runs the forecast whenever a new
manually-verified poll or a high-impact reviewed event appears.

IMPORTANT: this process must be deployed and kept running (e.g.
`celery -A ingestion.celery_app worker --beat -l info`, or separate
worker + beat processes in production) for any of this to happen — it is
not something that runs by itself just because the code exists in this
repository. See docs/DEPLOYMENT.md "24/7 ingestion & forecasting".
"""

from __future__ import annotations

from celery import Celery
from celery.schedules import crontab

from app.config import settings

celery_app = Celery("plc_ingestion", broker=settings.redis_url, backend=settings.redis_url)

celery_app.conf.beat_schedule = {
    "ingest-all-sources": {
        "task": "ingestion.tasks.ingest_all_sources_task",
        "schedule": settings.ingestion_poll_interval_minutes * 60,
    },
    # No-ops (return status "skipped_no_api_key") unless OPENAI_API_KEY is
    # set — see jobs.discover_news_via_ai / discover_polls_via_ai.
    "discover-news-via-ai": {
        "task": "ingestion.tasks.discover_news_via_ai_task",
        "schedule": settings.ingestion_poll_interval_minutes * 60,
    },
    "discover-polls-via-ai": {
        "task": "ingestion.tasks.discover_polls_via_ai_task",
        "schedule": settings.forecast_recompute_interval_minutes * 60,
    },
    "recompute-forecast-if-warranted": {
        "task": "ingestion.tasks.maybe_recompute_forecast_task",
        "schedule": settings.forecast_recompute_interval_minutes * 60,
    },
    # Coalition-signal scanning is heavier (re-reads recent articles'
    # extractions) — nightly is enough; alliance news does not move
    # minute-to-minute the way poll numbers conceptually could.
    "scan-coalition-signals-nightly": {
        "task": "ingestion.tasks.scan_coalition_signals_task",
        "schedule": crontab(hour=2, minute=0),
    },
}
celery_app.conf.timezone = "UTC"

celery_app.autodiscover_tasks(["ingestion"])
