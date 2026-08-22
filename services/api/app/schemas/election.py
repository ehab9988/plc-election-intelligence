from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from .common import ORMModel


class ElectionRuleSetOut(ORMModel):
    id: UUID
    version: str
    effective_from: datetime
    effective_until: datetime | None
    electoral_system: str
    district_structure: str
    total_seats: int
    threshold_fraction: float
    allocation_method: str
    reserved_seats: list | None
    gender_quota: dict | None
    minimum_candidate_age: int
    allows_individual_candidate_votes: bool
    source_document: str
    verified_at: datetime

    @property
    def majority_threshold(self) -> int:
        return (self.total_seats // 2) + 1


class ElectionOut(ORMModel):
    id: UUID
    name_en: str
    name_ar: str
    election_type: str
    scheduled_date: date | None
    is_current: bool
    status: str


class TimelineEventOut(ORMModel):
    id: UUID
    milestone: str
    label_en: str
    label_ar: str
    starts_at: datetime | None
    ends_at: datetime | None
    source_id: UUID | None
