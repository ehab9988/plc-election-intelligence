from __future__ import annotations

from datetime import date
from uuid import UUID

from pydantic import Field

from .common import ORMModel


class PollResultOut(ORMModel):
    label: str
    electoral_list_id: UUID | None
    raw_response_pct: float
    normalized_pct: float | None


class PollQuestionOut(ORMModel):
    id: UUID
    question_text_ar: str
    question_text_en: str | None
    question_type: str
    results: list[PollResultOut] = Field(default_factory=list)


class PollOut(ORMModel):
    id: UUID
    pollster_id: UUID
    sponsor: str | None
    publication_date: date
    fieldwork_start: date
    fieldwork_end: date
    sample_size: int
    margin_of_error: float | None
    mode: str
    geographic_population: str
    west_bank_sample_size: int | None
    gaza_sample_size: int | None
    population: str
    manually_verified: bool
    questions: list[PollQuestionOut] = Field(default_factory=list)


class PollingAveragePoint(ORMModel):
    electoral_list_id: UUID
    list_name_en: str
    list_name_ar: str
    weighted_average_pct: float
    trend_low: float
    trend_high: float
    n_polls_used: int
    most_recent_fieldwork_end: date | None
