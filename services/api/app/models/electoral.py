"""Electoral lists, list-party links, candidates and their ranking on a
closed list (sections 4, 10, 21)."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import RegistrationStatus
from .party import Person
from .types import UUID


class ElectoralList(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """A closed electoral list submitted for a given election. Distinct
    from Party because a list's public name can differ from its parent
    party/coalition's name (section 9)."""

    __tablename__ = "electoral_lists"

    election_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("elections.id"))
    list_name_ar: Mapped[str] = mapped_column(String(300))
    list_name_en: Mapped[str] = mapped_column(String(300))
    list_number: Mapped[int | None] = mapped_column(Integer, nullable=True)  # ballot/list number once assigned

    registration_status: Mapped[RegistrationStatus] = mapped_column(
        Enum(RegistrationStatus, name="registration_status"), default=RegistrationStatus.RUMORED
    )
    registration_status_source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )
    registration_status_effective_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    registration_status_verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    registration_status_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    cec_reference: Mapped[str | None] = mapped_column(String(300), nullable=True)

    color_hex: Mapped[str | None] = mapped_column(String(9), nullable=True)

    parties: Mapped[list[ElectoralListParty]] = relationship(back_populates="electoral_list")
    candidates: Mapped[list[Candidate]] = relationship(back_populates="electoral_list")


class ElectoralListParty(UUIDPrimaryKeyMixin, Base):
    """A list may be a single party's list or a coalition of several
    parties running jointly under one list."""

    __tablename__ = "electoral_list_parties"
    __table_args__ = (UniqueConstraint("electoral_list_id", "party_id"),)

    electoral_list_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("electoral_lists.id")
    )
    party_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))

    electoral_list: Mapped[ElectoralList] = relationship(back_populates="parties")


class Candidate(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """A person's candidacy on a specific electoral list at a specific
    rank. Never stores a fabricated individual vote share — see
    CandidateRanking / the forecasting engine for how seat probability is
    actually derived (list-rank vs. simulated party seats only)."""

    __tablename__ = "candidates"
    __table_args__ = (UniqueConstraint("electoral_list_id", "list_rank"),)

    person_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("people.id"))
    electoral_list_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("electoral_lists.id")
    )
    list_rank: Mapped[int] = mapped_column(Integer)
    candidate_status: Mapped[str] = mapped_column(String(50), default="listed")  # listed|withdrawn|disqualified
    is_reserved_seat_candidate: Mapped[bool] = mapped_column(Boolean, default=False)
    reserved_seat_category: Mapped[str | None] = mapped_column(String(100), nullable=True)

    person: Mapped[Person] = relationship()
    electoral_list: Mapped[ElectoralList] = relationship(back_populates="candidates")


class CandidateRanking(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Historical log of rank changes for a candidate (lists are sometimes
    amended before final CEC approval). Keeps candidates.list_rank as the
    current value while preserving history for audit/reproducibility."""

    __tablename__ = "candidate_rankings"

    candidate_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("candidates.id"))
    list_rank: Mapped[int] = mapped_column(Integer)
    effective_from: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )
