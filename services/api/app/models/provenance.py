"""Source-of-truth and provenance models (section 25-26).

Every important factual record must be traceable to a Source via a
Citation. When sources conflict, an EntityConflict is stored instead of
silently picking a winner (section 26).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import SourceTier, SourceType, VerificationConfidence
from .types import UUID


class Source(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "sources"

    name: Mapped[str] = mapped_column(String(300))
    source_type: Mapped[SourceType] = mapped_column(Enum(SourceType, name="source_type"))
    tier: Mapped[SourceTier] = mapped_column(Enum(SourceTier, name="source_tier"))
    url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    publisher: Mapped[str | None] = mapped_column(String(300), nullable=True)
    license_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Citation(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Links any factual record (entity_type + entity_id + field) to the
    Source that supports it, with a snippet of permitted evidence text."""

    __tablename__ = "citations"

    source_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sources.id"))
    entity_type: Mapped[str] = mapped_column(String(100))
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    field_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    evidence_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    retrieved_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence")
    )
    manually_verified: Mapped[bool] = mapped_column(Boolean, default=False)


class EntityConflict(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Stores competing claims about the same entity/field instead of
    silently resolving them (section 26)."""

    __tablename__ = "entity_conflicts"

    entity_type: Mapped[str] = mapped_column(String(100))
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    field_name: Mapped[str] = mapped_column(String(200))
    claim_a_value: Mapped[str] = mapped_column(Text)
    claim_a_citation_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("citations.id"))
    claim_b_value: Mapped[str] = mapped_column(Text)
    claim_b_citation_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("citations.id"))
    resolved: Mapped[bool] = mapped_column(Boolean, default=False)
    resolved_value: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
