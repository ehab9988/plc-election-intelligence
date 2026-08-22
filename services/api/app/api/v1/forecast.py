from __future__ import annotations

import uuid

from election_rules_py import majority_threshold
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from ...core.deps import require_role
from ...db import get_db
from ...models import (
    ElectionRuleSetORM,
    ElectoralList,
    ForecastCandidateResult,
    ForecastRun,
)
from ...models.enums import ForecastRunStatus, UserRole
from ...schemas.forecast import (
    ForecastCandidateResultOut,
    ForecastPartyResultOut,
    ForecastRunOut,
)
from ...services.forecast_runner import run_and_persist_forecast

router = APIRouter(prefix="/forecast", tags=["forecast"])


def _to_out(run: ForecastRun, db: Session) -> ForecastRunOut:
    list_meta = {
        el.id: el
        for el in db.scalars(
            select(ElectoralList).where(
                ElectoralList.id.in_([r.electoral_list_id for r in run.party_results])
            )
        )
    }
    party_results = [
        ForecastPartyResultOut(
            electoral_list_id=r.electoral_list_id,
            list_name_ar=list_meta[r.electoral_list_id].list_name_ar,
            list_name_en=list_meta[r.electoral_list_id].list_name_en,
            color_hex=list_meta[r.electoral_list_id].color_hex,
            polling_average_pct=r.polling_average_pct,
            forecast_vote_share_median=r.forecast_vote_share_median,
            vote_share_low80=r.vote_share_low80,
            vote_share_high80=r.vote_share_high80,
            vote_share_low95=r.vote_share_low95,
            vote_share_high95=r.vote_share_high95,
            seats_median=r.seats_median,
            seats_mean=r.seats_mean,
            seats_low50=r.seats_low50,
            seats_high50=r.seats_high50,
            seats_low80=r.seats_low80,
            seats_high80=r.seats_high80,
            seats_low95=r.seats_low95,
            seats_high95=r.seats_high95,
            probability_largest_list=r.probability_largest_list,
            probability_cross_threshold=r.probability_cross_threshold,
            probability_majority_alone=r.probability_majority_alone,
        )
        for r in run.party_results
        if r.electoral_list_id in list_meta
    ]
    rule_set = db.get(ElectionRuleSetORM, run.election_rule_set_id)
    return ForecastRunOut(
        id=run.id,
        election_id=run.election_id,
        model_version=run.model_version,
        dataset_version=run.dataset_version,
        data_cutoff_at=run.data_cutoff_at,
        simulations_performed=run.simulations_performed,
        random_seed=run.random_seed,
        status=run.status,
        assumptions_notes=run.assumptions_notes,
        change_summary=run.change_summary,
        published_at=run.published_at,
        created_at=run.created_at,
        majority_threshold=majority_threshold(rule_set.total_seats) if rule_set else 0,
        party_results=sorted(party_results, key=lambda r: -r.seats_median),
    )


@router.get("/latest", response_model=ForecastRunOut)
def get_latest_forecast(election_id: uuid.UUID, db: Session = Depends(get_db)) -> ForecastRunOut:
    stmt = (
        select(ForecastRun)
        .options(selectinload(ForecastRun.party_results))
        .where(ForecastRun.election_id == election_id, ForecastRun.status == ForecastRunStatus.PUBLISHED)
        .order_by(ForecastRun.created_at.desc())
        .limit(1)
    )
    run = db.scalar(stmt)
    if run is None:
        # fall back to most recent completed run if nothing has been
        # explicitly published yet (useful in dev/seed environments)
        stmt = (
            select(ForecastRun)
            .options(selectinload(ForecastRun.party_results))
            .where(ForecastRun.election_id == election_id, ForecastRun.status != ForecastRunStatus.FAILED)
            .order_by(ForecastRun.created_at.desc())
            .limit(1)
        )
        run = db.scalar(stmt)
    if run is None:
        raise HTTPException(404, "No forecast available for this election yet")
    return _to_out(run, db)


@router.get("/history", response_model=list[ForecastRunOut])
def get_forecast_history(election_id: uuid.UUID, db: Session = Depends(get_db)) -> list[ForecastRunOut]:
    stmt = (
        select(ForecastRun)
        .options(selectinload(ForecastRun.party_results))
        .where(ForecastRun.election_id == election_id)
        .order_by(ForecastRun.created_at.desc())
    )
    runs = list(db.scalars(stmt))
    return [_to_out(r, db) for r in runs]


@router.get("/{run_id}/parties", response_model=list[ForecastPartyResultOut])
def get_forecast_parties(run_id: uuid.UUID, db: Session = Depends(get_db)) -> list[ForecastPartyResultOut]:
    run = db.get(ForecastRun, run_id, options=[selectinload(ForecastRun.party_results)])
    if run is None:
        raise HTTPException(404, "Forecast run not found")
    return _to_out(run, db).party_results


@router.get("/{run_id}/candidates", response_model=list[ForecastCandidateResultOut])
def get_forecast_candidates(run_id: uuid.UUID, db: Session = Depends(get_db)) -> list[ForecastCandidateResult]:
    stmt = select(ForecastCandidateResult).where(ForecastCandidateResult.run_id == run_id)
    return list(db.scalars(stmt))


@router.post("/run", response_model=ForecastRunOut, status_code=201)
def trigger_forecast_run(
    election_id: uuid.UUID,
    n_simulations: int | None = None,
    db: Session = Depends(get_db),
    _analyst=Depends(require_role(UserRole.ANALYST)),
) -> ForecastRunOut:
    """Analyst/admin-only: triggers a new forecast run synchronously.
    Runs are immutable once created (section 39) — re-running never
    mutates a prior ForecastRun row."""
    try:
        run = run_and_persist_forecast(db, election_id, n_simulations=n_simulations)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    return _to_out(run, db)
