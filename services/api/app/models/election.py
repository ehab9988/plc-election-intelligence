"""Elections, versioned election rule sets, and election timelines
(sections 3, 6-60 baseline)."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from .types import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import ForecastRunStatus


class Election(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "elections"

    name_en: Mapped[str] = mapped_column(String(300))
    name_ar: Mapped[str] = mapped_column(String(300))
    election_type: Mapped[str] = mapped_column(String(50), default="legislative")
    scheduled_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_current: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(String(50), default="scheduled")

    rule_sets: Mapped[list["ElectionRuleSetORM"]] = relationship(back_populates="election")
    timeline_events: Mapped[list["ElectionTimelineEvent"]] = relationship(back_populates="election")


class ElectionRuleSetORM(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Persisted mirror of packages/election_rules_py.ElectionRuleSet.
    See section 3 — versioned so law changes never require a code change.
    """

    __tablename__ = "election_rule_sets"

    election_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("elections.id"))
    version: Mapped[str] = mapped_column(String(50))
    effective_from: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    effective_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    electoral_system: Mapped[str] = mapped_column(String(300))
    district_structure: Mapped[str] = mapped_column(String(300))
    total_seats: Mapped[int] = mapped_column(Integer)
    threshold_fraction: Mapped[float] = mapped_column(Float)
    allocation_method: Mapped[str] = mapped_column(String(50))

    reserved_seats: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    gender_quota: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    minimum_candidate_age: Mapped[int] = mapped_column(Integer)
    list_minimum_candidates: Mapped[int | None] = mapped_column(Integer, nullable=True)
    list_maximum_candidates: Mapped[int | None] = mapped_column(Integer, nullable=True)
    allows_individual_candidate_votes: Mapped[bool] = mapped_column(Boolean, default=False)

    source_document: Mapped[str] = mapped_column(Text)
    verified_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    election: Mapped["Election"] = relationship(back_populates="rule_sets")

    @property
    def majority_threshold(self) -> int:
        return (self.total_seats // 2) + 1


class ElectionTimelineEvent(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Registration / nomination / campaign / voting / results milestones
    (section 30 Election Calendar). Dates come from official CEC info, not
    hard-coded — see the seed script for the currently-cited baseline."""

    __tablename__ = "election_timelines"

    election_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("elections.id"))
    milestone: Mapped[str] = mapped_column(String(100))  # registration_open, nomination_close, ...
    label_en: Mapped[str] = mapped_column(String(300))
    label_ar: Mapped[str] = mapped_column(String(300))
    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )

    election: Mapped["Election"] = relationship(back_populates="timeline_events")
