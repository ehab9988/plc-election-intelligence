from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from .common import ORMModel


class PartyOut(ORMModel):
    id: UUID
    name_ar: str
    name_en: str
    abbreviation: str | None
    logo_url: str | None
    description_ar: str | None
    description_en: str | None
    registration_status: str
    registration_status_verified_at: datetime | None
    verification_confidence: str


class ElectoralListOut(ORMModel):
    id: UUID
    list_name_ar: str
    list_name_en: str
    list_number: int | None
    registration_status: str
    registration_status_verified_at: datetime | None
    cec_reference: str | None
    color_hex: str | None


class CandidateOut(ORMModel):
    id: UUID
    person_id: UUID
    electoral_list_id: UUID
    list_rank: int
    candidate_status: str
    is_reserved_seat_candidate: bool


class PersonOut(ORMModel):
    id: UUID
    full_name_ar: str
    full_name_en: str
    date_of_birth: date | None
    birthplace: str | None
    hometown: str | None
    current_position: str | None
    biography_ar: str | None
    biography_en: str | None
    photo_url: str | None
    verification_confidence: str
    last_verified_at: datetime | None


class CandidateDetailOut(ORMModel):
    candidate: CandidateOut
    person: PersonOut
    electoral_list: ElectoralListOut
    projected_party_seats_median: int | None = None
    seats_low80: int | None = None
    seats_high80: int | None = None
    seat_probability: float | None = None
