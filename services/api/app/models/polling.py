"""Polling database (sections 11-13). Deliberately verbose: distinguishing
methodology fields is what makes the polling average defensible instead of
naive arithmetic averaging."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import PollMode, PollPopulation
from .types import JSONB, UUID


class Pollster(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "pollsters"

    name_en: Mapped[str] = mapped_column(String(300))
    name_ar: Mapped[str] = mapped_column(String(300))
    abbreviation: Mapped[str | None] = mapped_column(String(50), nullable=True)
    website_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    methodology_transparency_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    ratings: Mapped[list[PollsterRating]] = relationship(back_populates="pollster")


class PollsterRating(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Historical-accuracy-derived house effect / quality rating for a
    pollster (section 12). Never adjusted for perceived political
    coverage — methodology-based only."""

    __tablename__ = "pollster_ratings"

    pollster_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("pollsters.id"))
    as_of: Mapped[date] = mapped_column(Date)
    quality_score: Mapped[float] = mapped_column(Float)  # 0-100, methodology-based
    house_effect_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    house_effect_by_party: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    historical_error_mae: Mapped[float | None] = mapped_column(Float, nullable=True)
    based_on_n_elections: Mapped[int | None] = mapped_column(Integer, nullable=True)

    pollster: Mapped[Pollster] = relationship(back_populates="ratings")


class Poll(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "polls"

    pollster_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("pollsters.id"))
    election_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("elections.id"))
    sponsor: Mapped[str | None] = mapped_column(String(300), nullable=True)
    source_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sources.id"))

    publication_date: Mapped[date] = mapped_column(Date)
    fieldwork_start: Mapped[date] = mapped_column(Date)
    fieldwork_end: Mapped[date] = mapped_column(Date)

    sample_size: Mapped[int] = mapped_column(Integer)
    margin_of_error: Mapped[float | None] = mapped_column(Float, nullable=True)
    methodology_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    mode: Mapped[PollMode] = mapped_column(Enum(PollMode, name="poll_mode"))
    sampling_procedure: Mapped[str | None] = mapped_column(Text, nullable=True)
    weighting_procedure: Mapped[str | None] = mapped_column(Text, nullable=True)

    geographic_population: Mapped[str] = mapped_column(String(200), default="West Bank and Gaza")
    west_bank_sample_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    gaza_sample_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    jerusalem_treatment_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    population: Mapped[PollPopulation] = mapped_column(Enum(PollPopulation, name="poll_population"))
    turnout_screen_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    manually_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    import_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    questions: Mapped[list[PollQuestion]] = relationship(back_populates="poll")
    geographic_results: Mapped[list[PollGeographicResult]] = relationship(back_populates="poll")

    __table_args__ = (
        UniqueConstraint("pollster_id", "fieldwork_start", "fieldwork_end", "election_id",
                          name="uq_poll_pollster_fieldwork"),
    )


class PollQuestion(UUIDPrimaryKeyMixin, Base):
    """A poll can carry more than one question. Section 11 forbids
    treating differently-worded questions as equivalent, so results are
    scoped to the specific PollQuestion that produced them, not just the
    Poll."""

    __tablename__ = "poll_questions"

    poll_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("polls.id"))
    question_text_ar: Mapped[str] = mapped_column(Text)
    question_text_en: Mapped[str | None] = mapped_column(Text, nullable=True)
    question_language: Mapped[str] = mapped_column(String(8), default="ar")
    question_type: Mapped[str] = mapped_column(String(100))
    # e.g. "party_support" vs "if_elections_held_today_vote_choice" —
    # distinct question types must never be merged (section 11).

    poll: Mapped[Poll] = relationship(back_populates="questions")
    results: Mapped[list[PollResult]] = relationship(back_populates="question")


class PollResult(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "poll_results"

    poll_question_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("poll_questions.id"))
    electoral_list_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("electoral_lists.id"), nullable=True
    )
    label: Mapped[str] = mapped_column(String(200))  # "undecided" | "would_not_vote" | "refused" | list name
    raw_response_pct: Mapped[float] = mapped_column(Float)
    normalized_pct: Mapped[float | None] = mapped_column(Float, nullable=True)

    question: Mapped[PollQuestion] = relationship(back_populates="results")


class PollGeographicResult(UUIDPrimaryKeyMixin, Base):
    """Geographic breakdown a pollster actually reported. Never derived by
    dividing national numbers (section 32) — if a pollster did not report
    it, this table simply has no row."""

    __tablename__ = "poll_geographic_results"

    poll_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("polls.id"))
    geographic_area_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("geographic_areas.id")
    )
    electoral_list_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("electoral_lists.id"))
    sample_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    value_pct: Mapped[float] = mapped_column(Float)
    insufficient_data: Mapped[bool] = mapped_column(Boolean, default=False)

    poll: Mapped[Poll] = relationship(back_populates="geographic_results")
