"""Runs one ingestion cycle directly — no Celery, no Redis, no
long-running process required. Used by
.github/workflows/publish-static-data.yml (the no-server deployment
path — see docs/STATIC_GITHUB_DEPLOYMENT.md), which spins up a fresh
runner per invocation and has nowhere to host a persistent broker/worker
anyway. It is equally usable as a plain cron job on any machine you do
have access to (`*/15 * * * * python scripts/run_ingestion_cycle.py`).

Runs, in order: ingest_all_sources -> discover_news_via_ai ->
discover_polls_via_ai -> discover_parties_via_ai ->
maybe_recompute_forecast. The three discover_*_via_ai steps no-op unless
OPENAI_API_KEY is set. Coalition signal scanning
(scan_coalition_signals) is heavier and does not need to run every
cycle — pass --with-coalition-scan to include it (the GitHub Actions
workflow does this once a day, not every scheduled run).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "api"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "ingestion"))

from ingestion import jobs


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

    print("Ingesting configured RSS news sources...", flush=True)
    results["ingest_all_sources"] = jobs.ingest_all_sources()

    print("Discovering news via OpenAI web search (no-op if OPENAI_API_KEY is unset)...", flush=True)
    results["discover_news_via_ai"] = jobs.discover_news_via_ai()

    print("Discovering polls via OpenAI web search (drafts UNVERIFIED rows only)...", flush=True)
    results["discover_polls_via_ai"] = jobs.discover_polls_via_ai()

    print("Discovering electoral lists/parties via OpenAI web search...", flush=True)
    results["discover_parties_via_ai"] = jobs.discover_parties_via_ai()

    print("Checking whether a forecast recompute is warranted...", flush=True)
    results["maybe_recompute_forecast"] = jobs.maybe_recompute_forecast()

    if args.with_coalition_scan:
        print("Scanning recent articles for coalition signals...", flush=True)
        results["scan_coalition_signals"] = jobs.scan_coalition_signals()

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
