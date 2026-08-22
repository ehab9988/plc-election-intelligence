"""Immutable forecast runs and their outputs (sections 14-20, 39-40).

A forecast_run is a snapshot: dataset_version + model_version + config +
seed are captured so the run remains reproducible and historical runs are
NEVER mutated in place (section 39)."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text
from .types import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import ForecastRunStatus


class ForecastRun(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "forecast_runs"

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    election_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("elections.id"))
    election_rule_set_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("election_rule_sets.id")
    )

    model_version: Mapped[str] = mapped_column(String(50))
    model_git_commit: Mapped[str | None] = mapped_column(String(64), nullable=True)
    dataset_version: Mapped[str] = mapped_column(String(50))
    data_cutoff_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    configuration: Mapped[dict] = mapped_column(JSONB)  # priors, poll weights, undecided method, etc.
    random_seed: Mapped[int] = mapped_column(Integer)
    simulations_performed: Mapped[int] = mapped_column(Integer)

    status: Mapped[ForecastRunStatus] = mapped_column(
        Enum(ForecastRunStatus, name="forecast_run_status"), default=ForecastRunStatus.RUNNING
    )
    assumptions_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    change_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    superseded_by_run_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("forecast_runs.id"), nullable=True
    )

    party_results: Mapped[list["ForecastPartyResult"]] = relationship(back_populates="run")
    candidate_results: Mapped[list["ForecastCandidateResult"]] = relationship(back_populates="run")


class ForecastPartyResult(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "forecast_party_results"

    run_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("forecast_runs.id"))
    electoral_list_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("electoral_lists.id"))

    polling_average_pct: Mapped[float] = mapped_column(Float)
    forecast_vote_share_median: Mapped[float] = mapped_column(Float)
    vote_share_low80: Mapped[float] = mapped_column(Float)
    vote_share_high80: Mapped[float] = mapped_column(Float)
    vote_share_low95: Mapped[float] = mapped_column(Float)
    vote_share_high95: Mapped[float] = mapped_column(Float)

    seats_median: Mapped[int] = mapped_column(Integer)
    seats_mean: Mapped[float] = mapped_column(Float)
    seats_low50: Mapped[int] = mapped_column(Integer)
    seats_high50: Mapped[int] = mapped_column(Integer)
    seats_low80: Mapped[int] = mapped_column(Integer)
    seats_high80: Mapped[int] = mapped_column(Integer)
    seats_low95: Mapped[int] = mapped_column(Integer)
    seats_high95: Mapped[int] = mapped_column(Integer)

    probability_largest_list: Mapped[float] = mapped_column(Float)
    probability_cross_threshold: Mapped[float] = mapped_column(Float)
    probability_majority_alone: Mapped[float] = mapped_column(Float)

    run: Mapped["ForecastRun"] = relationship(back_populates="party_results")


class ForecastCandidateResult(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "forecast_candidate_results"

    run_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("forecast_runs.id"))
    candidate_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("candidates.id"))
    seat_probability: Mapped[float] = mapped_column(Float)  # derived ONLY from list-rank vs. simulated party seats

    run: Mapped["ForecastRun"] = relationship(back_populates="candidate_results")


class ForecastDistribution(UUIDPrimaryKeyMixin, Base):
    """Optional stored histogram (seat count -> frequency) per list per
    run, so the UI can render a full probability distribution without
    re-running simulations (section 58)."""

    __tablename__ = "forecast_distributions"

    run_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("forecast_runs.id"))
    electoral_list_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("electoral_lists.id"))
    histogram: Mapped[dict] = mapped_column(JSONB)  # {"seat_count": frequency, ...}


class SimulationsSummary(UUIDPrimaryKeyMixin, Base):
    """Aggregate run-level diagnostics (section 41): calibration inputs,
    staleness flags, etc."""

    __tablename__ = "simulations_summary"

    run_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("forecast_runs.id"))
    most_recent_poll_age_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    elevated_uncertainty: Mapped[bool] = mapped_column(default=False)
    elevated_uncertainty_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    diagnostics: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
