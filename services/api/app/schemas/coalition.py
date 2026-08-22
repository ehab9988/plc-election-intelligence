from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel

from .common import ORMModel


class CoalitionSimulateRequest(BaseModel):
    forecast_run_id: UUID
    electoral_list_ids: list[UUID]


class CoalitionSimulateResponse(BaseModel):
    electoral_list_ids: list[UUID]
    majority_threshold: int
    seats_median: int
    seats_low80: int
    seats_high80: int
    majority_probability: float


class CoalitionEvidenceOut(ORMModel):
    id: UUID
    party_a_id: UUID
    party_b_id: UUID
    evidence_type: str
    statement_summary: str
    source_id: UUID
    confidence: str
