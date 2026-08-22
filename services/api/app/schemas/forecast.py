"""Forecast API contracts. Terminology follows section 81 strictly — a
forecast payload always separates polling average / nowcast / election-day
forecast, and every numeric field is labeled with what it is, never a bare
number presented as fact (section 2)."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from .common import ORMModel


class ForecastPartyResultOut(ORMModel):
    electoral_list_id: UUID
    list_name_ar: str
    list_name_en: str
    color_hex: str | None

    polling_average_pct: float
    forecast_vote_share_median: float
    vote_share_low80: float
    vote_share_high80: float
    vote_share_low95: float
    vote_share_high95: float

    seats_median: int
    seats_mean: float
    seats_low50: int
    seats_high50: int
    seats_low80: int
    seats_high80: int
    seats_low95: int
    seats_high95: int

    probability_largest_list: float
    probability_cross_threshold: float
    probability_majority_alone: float


class ForecastCandidateResultOut(ORMModel):
    candidate_id: UUID
    seat_probability: float


class ForecastRunOut(ORMModel):
    id: UUID
    election_id: UUID
    model_version: str
    dataset_version: str
    data_cutoff_at: datetime
    simulations_performed: int
    random_seed: int
    status: str
    assumptions_notes: str | None
    change_summary: str | None
    published_at: datetime | None
    created_at: datetime

    majority_threshold: int
    party_results: list[ForecastPartyResultOut] = []


class ModelPerformanceOut(ORMModel):
    """Backtesting summary (section 18, 41) — never a marketing claim,
    always tied to a rolling-origin evaluation."""

    model_version: str
    evaluation_period_start: str
    evaluation_period_end: str
    mean_absolute_error_vote_share: float | None
    brier_score: float | None
    interval_coverage_80pct: float | None
    notes: str
