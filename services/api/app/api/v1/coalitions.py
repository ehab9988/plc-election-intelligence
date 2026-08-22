from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...db import get_db
from ...models import CoalitionEvidence, ElectionRuleSetORM, ForecastRun
from ...schemas.coalition import (
    CoalitionEvidenceOut,
    CoalitionSimulateRequest,
    CoalitionSimulateResponse,
)

router = APIRouter(prefix="/coalitions", tags=["coalitions"])


@router.get("", response_model=list[CoalitionEvidenceOut])
def list_coalition_evidence(
    party_id: uuid.UUID | None = None, db: Session = Depends(get_db)
) -> list[CoalitionEvidence]:
    stmt = select(CoalitionEvidence)
    if party_id:
        stmt = stmt.where(
            (CoalitionEvidence.party_a_id == party_id) | (CoalitionEvidence.party_b_id == party_id)
        )
    return list(db.scalars(stmt))


@router.post("/simulate", response_model=CoalitionSimulateResponse)
def simulate_coalition_endpoint(
    body: CoalitionSimulateRequest, db: Session = Depends(get_db)
) -> CoalitionSimulateResponse:
    """Mathematical feasibility only (section 22A) — computed live from the
    named forecast run's stored per-simulation seat outcomes. Political
    compatibility (22B) is served separately via GET /coalitions."""
    from ...models import ForecastDistribution

    run = db.get(ForecastRun, body.forecast_run_id)
    if run is None:
        raise HTTPException(404, "Forecast run not found")
    rule_set = db.get(ElectionRuleSetORM, run.election_rule_set_id)
    total_seats = rule_set.total_seats

    # Reconstruct approximate per-simulation seat draws from stored
    # per-list histograms. This is an approximation (loses cross-list
    # correlation) suitable for the vertical slice; production should
    # instead persist a compact simulation sample per run (see
    # docs/COALITION_MODEL.md "Known limitation").
    histograms = {
        str(d.electoral_list_id): d.histogram
        for d in db.scalars(
            select(ForecastDistribution).where(ForecastDistribution.run_id == run.id)
        )
    }
    from election_rules_py import SimulationSummary, majority_threshold

    medians = []
    for lid in body.electoral_list_ids:
        hist = histograms.get(str(lid), {})
        if not hist:
            continue
        values: list[float] = []
        for seats_str, freq in hist.items():
            values.extend([float(seats_str)] * freq)
        medians.append(SimulationSummary.from_values(values))

    if not medians:
        raise HTTPException(400, "No forecast data available for the selected lists")

    seats_median = round(sum(s.median for s in medians))
    seats_low80 = round(sum(s.low80 for s in medians))
    seats_high80 = round(sum(s.high80 for s in medians))
    threshold = majority_threshold(total_seats)

    # Approximate majority probability from summed medians/spread; a
    # correlated joint estimate requires the raw simulation sample (see
    # limitation note above).
    majority_probability = 1.0 if seats_median >= threshold else max(
        0.0, min(1.0, (seats_high80 - threshold) / max(seats_high80 - seats_low80, 1))
    )

    return CoalitionSimulateResponse(
        electoral_list_ids=body.electoral_list_ids,
        majority_threshold=threshold,
        seats_median=seats_median,
        seats_low80=seats_low80,
        seats_high80=seats_high80,
        majority_probability=round(majority_probability, 4),
    )
