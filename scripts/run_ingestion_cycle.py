"""Runs one ingestion cycle directly — no Celery, no Redis, no
long-running process required. Built for a GitHub Actions scheduled
workflow (see .github/workflows/ingestion-cron.yml and
docs/FREE_TIER_DEPLOYMENT.md), which spins up a fresh runner per
invocation and has nowhere to host a persistent broker/worker anyway.
It is equally usable as a plain cron job on any machine you do have
access to (`*/15 * * * * python scripts/run_ingestion_cycle.py`).

Runs, in order: ingest_all_sources -> maybe_recompute_forecast. Coalition
signal scanning (scan_coalition_signals) is heavier and does not need to
run every cycle — pass --with-coalition-scan to include it (the GitHub
Actions workflow does this once a day, not every 15-minute run).

This script could not be executed in this repository's development
sandbox (no working Python runtime — see README "What could not be
verified").
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "api"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "ingestion"))

from ingestion import jobs  # noqa: E402  (import after sys.path setup)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--with-coalition-scan",
        action="store_true",
        help="Also run scan_coalition_signals this cycle (heavier; the GitHub Actions "
        "workflow only sets this on its once-daily run, not every 15-minute run).",
    )
    args = parser.parse_args()

    results: dict[str, dict] = {}

    print("Ingesting configured news sources...", flush=True)
    results["ingest_all_sources"] = jobs.ingest_all_sources()

    print("Checking whether a forecast recompute is warranted...", flush=True)
    results["maybe_recompute_forecast"] = jobs.maybe_recompute_forecast()

    if args.with_coalition_scan:
        print("Scanning recent articles for coalition signals...", flush=True)
        results["scan_coalition_signals"] = jobs.scan_coalition_signals()

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
