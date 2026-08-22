"""Exports the current election's data as static JSON files, mirroring the
exact shape of the FastAPI endpoints under services/api/app/api/v1, for
the Flutter client's "static" (GitHub-hosted) data source — a deployment
path with no live server: a GitHub Actions job runs this script and
commits the output to the repo, and the client fetches the files directly
from raw.githubusercontent.com. See docs/STATIC_GITHUB_DEPLOYMENT.md.

This reuses the same router functions and Pydantic schemas the live API
uses (calling them directly with a db session, bypassing FastAPI's
request/dependency-injection layer), so the JSON shape here is always
identical to what a live API would return for the same data — one
serialization path, not two to keep in sync.

Usage:
    cd services/api
    python ../../scripts/export_static_data.py [output_dir]

Defaults to <repo_root>/data/. Respects DATABASE_URL like the API itself
(see app/config.py) — defaults to the local SQLite dev DB.
"""

from __future__ import annotations

import json
import sys
import uuid
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "services" / "api"))

from app.api.v1.coalitions import list_coalition_evidence, list_formation_estimates
from app.api.v1.elections import (
    get_current_election,
    get_election_rules,
    get_election_timeline,
)
from app.api.v1.forecast import _to_out as forecast_to_out
from app.api.v1.news import ArticleOut, list_news
from app.api.v1.parties import (
    get_candidate,
    list_candidates,
    list_parties,
)
from app.api.v1.polls import list_polls, polling_average
from app.db import SessionLocal
from app.models import ElectoralList, ForecastRun
from app.models.enums import ForecastRunStatus
from app.schemas.coalition import CoalitionEvidenceOut, CoalitionFormationEstimateOut
from app.schemas.election import (
    ElectionOut,
    ElectionRuleSetOut,
    TimelineEventOut,
)
from app.schemas.party import CandidateOut, ElectoralListOut, PartyOut
from app.schemas.poll import PollOut
from sqlalchemy import select
from sqlalchemy.orm import Session


def _json_default(o: Any) -> Any:
    if isinstance(o, uuid.UUID):
        return str(o)
    if isinstance(o, (datetime, date)):
        return o.isoformat()
    raise TypeError(f"not JSON serializable: {o!r}")


def _dump(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, list):
        return [_dump(v) for v in value]
    return value


def _write(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(_dump(value), ensure_ascii=False, indent=2, default=_json_default),
        encoding="utf-8",
    )
    print(f"wrote {path.relative_to(REPO_ROOT)}")


def export(db: Session, out_dir: Path) -> None:
    election = ElectionOut.model_validate(get_current_election(db=db))
    election_id = election.id
    _write(out_dir / "elections" / "current.json", election)
    _write(
        out_dir / "elections" / str(election_id) / "rules.json",
        ElectionRuleSetOut.model_validate(get_election_rules(election_id, db=db)),
    )
    _write(
        out_dir / "elections" / str(election_id) / "timeline.json",
        [TimelineEventOut.model_validate(e) for e in get_election_timeline(election_id, db=db)],
    )

    stmt = (
        select(ForecastRun)
        .where(ForecastRun.election_id == election_id, ForecastRun.status != ForecastRunStatus.FAILED)
        .order_by(ForecastRun.created_at.desc())
    )
    runs = list(db.scalars(stmt))
    if runs:
        _write(out_dir / "forecast" / "latest" / f"{election_id}.json", forecast_to_out(runs[0], db))
        _write(
            out_dir / "forecast" / "history" / f"{election_id}.json",
            [forecast_to_out(r, db) for r in runs],
        )
    else:
        print(f"no forecast runs for election {election_id} — skipping forecast export")

    parties = [PartyOut.model_validate(p) for p in list_parties(q=None, db=db)]
    _write(out_dir / "parties.json", parties)

    electoral_lists = list(db.scalars(select(ElectoralList).where(ElectoralList.election_id == election_id)))
    _write(out_dir / "electoral_lists.json", [ElectoralListOut.model_validate(el) for el in electoral_lists])

    for el in electoral_lists:
        candidates = [CandidateOut.model_validate(c) for c in list_candidates(electoral_list_id=el.id, db=db)]
        _write(out_dir / "candidates" / "by-list" / f"{el.id}.json", candidates)
        for c in candidates:
            _write(out_dir / "candidates" / f"{c.id}.json", get_candidate(candidate_id=c.id, db=db))

    _write(
        out_dir / "polls.json",
        [PollOut.model_validate(p) for p in list_polls(election_id=election_id, db=db)],
    )
    _write(out_dir / "polling-average.json", polling_average(election_id=election_id, db=db))

    _write(out_dir / "news.json", [ArticleOut.model_validate(a) for a in list_news(limit=50, db=db)])

    evidence = [CoalitionEvidenceOut.model_validate(e) for e in list_coalition_evidence(party_id=None, db=db)]
    _write(out_dir / "coalitions" / "all.json", evidence)
    party_ids = {e.party_a_id for e in evidence} | {e.party_b_id for e in evidence}
    for pid in party_ids:
        _write(
            out_dir / "coalitions" / "by-party" / f"{pid}.json",
            [e for e in evidence if e.party_a_id == pid or e.party_b_id == pid],
        )

    estimates = [
        CoalitionFormationEstimateOut.model_validate(e) for e in list_formation_estimates(party_id=None, db=db)
    ]
    _write(out_dir / "coalitions" / "formation-estimates.json", estimates)

    _write(
        out_dir / "meta.json",
        {"generated_at": datetime.now(UTC).isoformat(), "election_id": str(election_id)},
    )


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO_ROOT / "data"
    session = SessionLocal()
    try:
        export(session, out)
    finally:
        session.close()
