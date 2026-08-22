"""Coalition Lab persistence (sections 22-23): mathematical feasibility is
computed straight from simulations at request time; evidence supporting or
against political compatibility is stored here, sourced and dated."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Boolean, Date, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import VerificationConfidence
from .types import ARRAY, UUID


class CoalitionScenario(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """A named, saved combination of lists a user or analyst built in the
    Coalition Lab, or an auto-generated scenario (e.g. "smallest majority
    coalition")."""

    __tablename__ = "coalition_scenarios"

    forecast_run_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("forecast_runs.id"))
    name: Mapped[str] = mapped_column(String(300))
    scenario_type: Mapped[str] = mapped_column(String(50))  # user_defined | auto_smallest_majority | auto_broad_unity | announced
    electoral_list_ids: Mapped[list[uuid.UUID]] = mapped_column(ARRAY(UUID(as_uuid=True)))

    seats_median: Mapped[int] = mapped_column(Integer)
    seats_low80: Mapped[int] = mapped_column(Integer)
    seats_high80: Mapped[int] = mapped_column(Integer)
    majority_probability: Mapped[float] = mapped_column(Float)


class CoalitionEvidence(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """One piece of evidence (statement, alliance, dispute, negotiation)
    bearing on whether two parties are politically compatible. Feeds a
    qualitative 'compatibility score', never a fabricated 'probability of
    coalition formation' unless a calibrated methodology exists."""

    __tablename__ = "coalition_evidence"

    party_a_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    party_b_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    evidence_type: Mapped[str] = mapped_column(String(100))  # supporting | conflicting
    # Distinct from evidence_type: whether this specific piece of evidence
    # reports the two parties running (or announcing they will run) on ONE
    # unified electoral list, vs. a broader political alliance/governing
    # coalition that still files separately. Still never a probability —
    # a categorical, sourced signal like every other field here.
    implies_joint_list: Mapped[bool] = mapped_column(Boolean, default=False)
    statement_summary: Mapped[str] = mapped_column(Text)
    statement_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    source_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sources.id"))
    confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence"),
        default=VerificationConfidence.UNVERIFIED,
    )
