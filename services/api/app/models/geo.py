"""Geographic hierarchy (section 32): Palestine -> West Bank/Gaza ->
governorate -> locality."""

from __future__ import annotations

import uuid

from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .types import UUID


class GeographicArea(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "geographic_areas"

    name_ar: Mapped[str] = mapped_column(String(200))
    name_en: Mapped[str] = mapped_column(String(200))
    level: Mapped[str] = mapped_column(String(50))  # country | region | governorate | locality
    region: Mapped[str | None] = mapped_column(String(50), nullable=True)  # west_bank | gaza | jerusalem
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("geographic_areas.id"), nullable=True
    )
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)

    parent: Mapped[GeographicArea] = relationship(remote_side="GeographicArea.id")
