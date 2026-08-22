"""Users, subscriptions, notifications, audit log (sections 27, 36, 43)."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import UserRole
from .types import JSONB, UUID


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    display_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, name="user_role"), default=UserRole.USER)
    preferred_language: Mapped[str] = mapped_column(String(8), default="ar")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Subscription(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "subscriptions"

    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    plan: Mapped[str] = mapped_column(String(50))  # free | premium | professional
    billing_provider: Mapped[str] = mapped_column(String(50))  # google_play | external_checkout
    external_reference: Mapped[str | None] = mapped_column(String(300), nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    current_period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Notification(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    kind: Mapped[str] = mapped_column(String(100))
    title: Mapped[str] = mapped_column(String(300))
    body: Mapped[str] = mapped_column(Text)
    payload: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AuditLog(UUIDPrimaryKeyMixin, Base):
    """Immutable audit trail for every analyst/admin modification (section 27)."""

    __tablename__ = "audit_logs"

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    action: Mapped[str] = mapped_column(String(100))
    entity_type: Mapped[str] = mapped_column(String(100))
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    previous_value: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    new_value: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sources.id"), nullable=True
    )


class ApiKey(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Commercial API access keys (section 37)."""

    __tablename__ = "api_keys"

    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    key_hash: Mapped[str] = mapped_column(String(255), unique=True)
    label: Mapped[str] = mapped_column(String(200))
    rate_limit_per_minute: Mapped[int] = mapped_column(default=60)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
