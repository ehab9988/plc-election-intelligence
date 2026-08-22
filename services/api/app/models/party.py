"""Parties, people, aliases, and typed relationships (section 10).

Political relationships are NEVER reduced to a single "belongs to" field —
see PartyPersonRelationship / PartyPartyRelationship, which carry a type,
date range, source, and confidence.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import RegistrationStatus, RelationshipType, VerificationConfidence
from .types import UUID


class Party(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "parties"

    name_ar: Mapped[str] = mapped_column(String(300))
    name_en: Mapped[str] = mapped_column(String(300))
    abbreviation: Mapped[str | None] = mapped_column(String(50), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    description_ar: Mapped[str | None] = mapped_column(Text, nullable=True)
    description_en: Mapped[str | None] = mapped_column(Text, nullable=True)
    founding_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    political_affiliation: Mapped[str | None] = mapped_column(String(200), nullable=True)
    website_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

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
    verification_confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence"),
        default=VerificationConfidence.UNVERIFIED,
    )

    aliases: Mapped[list[PartyAlias]] = relationship(back_populates="party")


class PartyAlias(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "party_aliases"

    party_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    alias: Mapped[str] = mapped_column(String(300))
    language: Mapped[str] = mapped_column(String(8), default="ar")
    alias_type: Mapped[str] = mapped_column(String(50), default="name_variant")  # name_variant | abbreviation | transliteration

    party: Mapped[Party] = relationship(back_populates="aliases")


class Person(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "people"

    full_name_ar: Mapped[str] = mapped_column(String(300))
    full_name_en: Mapped[str] = mapped_column(String(300))
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    birthplace: Mapped[str | None] = mapped_column(String(300), nullable=True)
    hometown: Mapped[str | None] = mapped_column(String(300), nullable=True)
    governorate_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("geographic_areas.id"), nullable=True
    )
    current_position: Mapped[str | None] = mapped_column(String(300), nullable=True)
    biography_ar: Mapped[str | None] = mapped_column(Text, nullable=True)
    biography_en: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    photo_license_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    verification_confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence"),
        default=VerificationConfidence.UNVERIFIED,
    )
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    aliases: Mapped[list[PersonAlias]] = relationship(back_populates="person")


class PersonAlias(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "person_aliases"

    person_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("people.id"))
    alias: Mapped[str] = mapped_column(String(300))
    language: Mapped[str] = mapped_column(String(8), default="ar")
    alias_type: Mapped[str] = mapped_column(String(50), default="name_variant")

    person: Mapped[Person] = relationship(back_populates="aliases")


class PartyPersonRelationship(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Typed, sourced, time-bounded relationship between a person and a
    party (section 10). E.g. LED_BY, MEMBER_OF, ENDORSED_BY."""

    __tablename__ = "party_person_relationships"

    party_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    person_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("people.id"))
    relationship_type: Mapped[RelationshipType] = mapped_column(
        Enum(RelationshipType, name="relationship_type")
    )
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )
    confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence"),
        default=VerificationConfidence.UNVERIFIED,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class PartyPartyRelationship(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Typed relationship between two parties: COALITION_WITH, SPLIT_FROM,
    AFFILIATED_WITH, etc. Backs the Coalition Evidence Graph (section 22)."""

    __tablename__ = "party_party_relationships"

    party_a_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    party_b_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("parties.id"))
    relationship_type: Mapped[RelationshipType] = mapped_column(
        Enum(RelationshipType, name="relationship_type")
    )
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )
    confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence"),
        default=VerificationConfidence.UNVERIFIED,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
