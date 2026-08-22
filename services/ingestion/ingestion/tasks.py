"""Celery task wrappers around jobs.py, for a deployment that runs a real
Celery worker + beat process on a server (docs/DEPLOYMENT.md).

If you have no server to run Celery/Redis on, see
scripts/run_ingestion_cycle.py and docs/FREE_TIER_DEPLOYMENT.md instead —
it calls the exact same jobs.py functions directly, driven by a GitHub
Actions scheduled workflow rather than a long-running worker process.
"""

from __future__ import annotations

from celery import shared_task

from . import jobs


@shared_task(name="ingestion.tasks.ingest_all_sources_task")
def ingest_all_sources_task() -> dict:
    return jobs.ingest_all_sources()


@shared_task(name="ingestion.tasks.maybe_recompute_forecast_task")
def maybe_recompute_forecast_task() -> dict:
    return jobs.maybe_recompute_forecast()


@shared_task(name="ingestion.tasks.scan_coalition_signals_task")
def scan_coalition_signals_task() -> dict:
    return jobs.scan_coalition_signals()
