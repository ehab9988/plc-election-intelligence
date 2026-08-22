"""Orchestrates one forecast run: polling average -> Monte Carlo ->
candidate probabilities -> persisted, immutable ForecastRun (sections
14-20, 39-40).

For the vertical slice this runs synchronously inside the request/CLI
process. In production, wire this behind the ingestion service's job
queue (Celery/RQ/Dramatiq per section 6) so it runs on a schedule and
after every new high-quality poll, rather than blocking an API call.
"""

from __future__ import annotations

import random
import uuid
from datetime import UTC, date, datetime

from election_rules_py import AllocationMethod, ElectionRuleSet
from forecasting.candidate_forecast import compute_candidate_forecasts
from forecasting.monte_carlo import ForecastInputs, run_monte_carlo
from forecasting.polling_average import (
    PollObservation,
    WeightingConfig,
    compute_polling_average,
)
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from ..config import settings
from ..models import (
    Candidate,
    Election,
    ElectionRuleSetORM,
    ElectoralList,
    ForecastCandidateResult,
    ForecastDistribution,
    ForecastPartyResult,
    ForecastRun,
    Poll,
    PollQuestion,
    SimulationsSummary,
)
from ..models.enums import ForecastRunStatus

MODEL_VERSION = "forecast-model-0.1.0"


def _orm_rules_to_engine_rules(orm_rules: ElectionRuleSetORM) -> ElectionRuleSet:
    return ElectionRuleSet(
        id=str(orm_rules.id),
        election_id=str(orm_rules.election_id),
        version=orm_rules.version,
        effective_from=orm_rules.effective_from,
        effective_until=orm_rules.effective_until,
        electoral_system=orm_rules.electoral_system,
        district_structure=orm_rules.district_structure,
        total_seats=orm_rules.total_seats,
        threshold_fraction=orm_rules.threshold_fraction,
        allocation_method=AllocationMethod(orm_rules.allocation_method),
        minimum_candidate_age=orm_rules.minimum_candidate_age,
        source_document=orm_rules.source_document,
        verified_at=orm_rules.verified_at,
    )


def run_and_persist_forecast(
    db: Session,
    election_id: uuid.UUID,
    n_simulations: int | None = None,
    random_seed: int | None = None,
    change_summary: str | None = None,
) -> ForecastRun:
    election = db.get(Election, election_id)
    if election is None:
        raise ValueError(f"Election {election_id} not found")

    rule_stmt = (
        select(ElectionRuleSetORM)
        .where(ElectionRuleSetORM.election_id == election_id)
        .order_by(ElectionRuleSetORM.effective_from.desc())
        .limit(1)
    )
    orm_rules = db.scalar(rule_stmt)
    if orm_rules is None:
        raise ValueError(f"No ElectionRuleSet configured for election {election_id}")
    rules = _orm_rules_to_engine_rules(orm_rules)

    electoral_lists = list(
        db.scalars(select(ElectoralList).where(ElectoralList.election_id == election_id))
    )
    list_ids = [str(el.id) for el in electoral_lists]

    poll_stmt = (
        select(Poll)
        .options(selectinload(Poll.questions).selectinload(PollQuestion.results))
        .where(Poll.election_id == election_id)
    )
    polls = list(db.scalars(poll_stmt))

    observations: list[PollObservation] = []
    most_recent_fieldwork_end: date | None = None
    for poll in polls:
        if most_recent_fieldwork_end is None or poll.fieldwork_end > most_recent_fieldwork_end:
            most_recent_fieldwork_end = poll.fieldwork_end
        for question in poll.questions:
            if question.question_type != "vote_choice_if_today":
                continue
            for result in question.results:
                if result.electoral_list_id is None:
                    continue
                observations.append(
                    PollObservation(
                        poll_id=str(poll.id),
                        pollster_id=str(poll.pollster_id),
                        electoral_list_id=str(result.electoral_list_id),
                        pct=result.normalized_pct or result.raw_response_pct,
                        sample_size=poll.sample_size,
                        fieldwork_end=poll.fieldwork_end,
                        population=poll.population.value,
                        pollster_quality_score=70.0,
                    )
                )

    today = datetime.now(UTC).date()
    averages = compute_polling_average(observations, as_of=today, cfg=WeightingConfig())
    polling_average_pct = {lid: avg.weighted_average_pct for lid, avg in averages.items()}

    days_stale = (today - most_recent_fieldwork_end).days if most_recent_fieldwork_end else 999

    seed = random_seed if random_seed is not None else random.randint(1, 2**31 - 1)
    sims = n_simulations or settings.default_monte_carlo_simulations

    inputs = ForecastInputs(
        list_ids=list_ids,
        polling_average_pct=polling_average_pct,
        n_simulations=sims,
        random_seed=seed,
        days_since_last_quality_poll=max(days_stale, 0),
    )
    output = run_monte_carlo(inputs, rules)

    forecast_run = ForecastRun(
        id=uuid.uuid4(),
        created_at=datetime.now(UTC),
        election_id=election_id,
        election_rule_set_id=orm_rules.id,
        model_version=MODEL_VERSION,
        model_git_commit=None,
        dataset_version=f"polls-as-of-{today.isoformat()}",
        data_cutoff_at=datetime.now(UTC),
        configuration={
            "dirichlet_concentration": inputs.dirichlet_concentration,
            "house_effect_std_pct": inputs.house_effect_std_pct,
            "turnout_noise_std_pct": inputs.turnout_noise_std_pct,
            "undecided_allocation": inputs.undecided_allocation,
        },
        random_seed=seed,
        simulations_performed=sims,
        status=ForecastRunStatus.COMPLETED,
        assumptions_notes=(
            "Undecided voters allocated proportionally. House effects and "
            "turnout modeled as independent Gaussian noise. See "
            "docs/FORECAST_MODEL.md for full methodology and limitations."
        ),
        change_summary=change_summary,
    )
    db.add(forecast_run)
    db.flush()

    for lid, result in output.list_results.items():
        db.add(
            ForecastPartyResult(
                run_id=forecast_run.id,
                electoral_list_id=uuid.UUID(lid),
                polling_average_pct=polling_average_pct.get(lid, 0.0),
                forecast_vote_share_median=result.vote_share_summary.median,
                vote_share_low80=result.vote_share_summary.low80,
                vote_share_high80=result.vote_share_summary.high80,
                vote_share_low95=result.vote_share_summary.low95,
                vote_share_high95=result.vote_share_summary.high95,
                seats_median=int(result.seats_summary.median),
                seats_mean=result.seats_summary.mean,
                seats_low50=int(result.seats_summary.low50),
                seats_high50=int(result.seats_summary.high50),
                seats_low80=int(result.seats_summary.low80),
                seats_high80=int(result.seats_summary.high80),
                seats_low95=int(result.seats_summary.low95),
                seats_high95=int(result.seats_summary.high95),
                probability_largest_list=result.probability_largest_list,
                probability_cross_threshold=result.probability_cross_threshold,
                probability_majority_alone=result.probability_majority_alone,
            )
        )
        histogram: dict[str, int] = {}
        for sim in output.raw_seat_simulations:
            seats = sim.get(lid, 0)
            histogram[str(seats)] = histogram.get(str(seats), 0) + 1
        db.add(
            ForecastDistribution(run_id=forecast_run.id, electoral_list_id=uuid.UUID(lid), histogram=histogram)
        )

    candidates = list(db.scalars(select(Candidate).where(Candidate.electoral_list_id.in_([el.id for el in electoral_lists]))))
    candidates_by_list: dict[str, list[tuple[str, int]]] = {}
    for c in candidates:
        candidates_by_list.setdefault(str(c.electoral_list_id), []).append((str(c.id), c.list_rank))

    candidate_forecasts = compute_candidate_forecasts(output, candidates_by_list)
    for cf in candidate_forecasts:
        db.add(
            ForecastCandidateResult(
                run_id=forecast_run.id,
                candidate_id=uuid.UUID(cf.candidate_id),
                seat_probability=cf.seat_probability,
            )
        )

    db.add(
        SimulationsSummary(
            run_id=forecast_run.id,
            most_recent_poll_age_days=days_stale if most_recent_fieldwork_end else None,
            elevated_uncertainty=days_stale > 30,
            elevated_uncertainty_reason=(
                f"Most recent quality poll fieldwork ended {days_stale} days ago."
                if days_stale > 30
                else None
            ),
        )
    )

    db.commit()
    db.refresh(forecast_run)
    return forecast_run
