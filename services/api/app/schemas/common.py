from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class SourceRef(ORMModel):
    id: UUID
    name: str
    source_type: str
    tier: str
    url: str | None = None


class FreshnessMeta(BaseModel):
    """Attached to any dynamic payload so the client can render a
    "Forecast updated 18 minutes ago" style banner (section 66) instead of
    silently implying live data."""

    generated_at: datetime
    data_cutoff_at: datetime | None = None
