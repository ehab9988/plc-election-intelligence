"""Dialect-portable column types.

Production always runs against Postgres, where these delegate to the
native ``postgresql.UUID`` / ``JSONB`` / ``ARRAY`` types with no behavior
change. On any other dialect (SQLite, used by the test suite when no
throwaway Postgres database is available) they fall back to a portable
representation, so the exact same models compile and run against either
backend.
"""

from __future__ import annotations

import uuid

from sqlalchemy import CHAR, JSON, TypeDecorator
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy.dialects.postgresql import JSONB as PG_JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID


class UUID(TypeDecorator):
    """Native ``postgresql.UUID`` on Postgres, ``CHAR(36)`` elsewhere."""

    impl = CHAR
    cache_ok = True

    def __init__(self, as_uuid: bool = True, *args, **kwargs):
        self.as_uuid = as_uuid
        super().__init__(*args, **kwargs)

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=self.as_uuid))
        return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None or dialect.name == "postgresql":
            return value
        return str(value if isinstance(value, uuid.UUID) else uuid.UUID(str(value)))

    def process_result_value(self, value, dialect):
        if value is None or dialect.name == "postgresql":
            return value
        return uuid.UUID(value) if self.as_uuid and not isinstance(value, uuid.UUID) else value


class JSONB(TypeDecorator):
    """Native ``postgresql.JSONB`` on Postgres, ``JSON`` elsewhere."""

    impl = JSON
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_JSONB())
        return dialect.type_descriptor(JSON())


class ARRAY(TypeDecorator):
    """Native ``postgresql.ARRAY`` on Postgres, JSON-encoded list elsewhere."""

    impl = JSON
    cache_ok = True

    def __init__(self, item_type, *args, **kwargs):
        self.item_type = item_type
        super().__init__(*args, **kwargs)

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_ARRAY(self.item_type))
        return dialect.type_descriptor(JSON())

    def process_bind_param(self, value, dialect):
        if value is None or dialect.name == "postgresql":
            return value
        return [str(v) for v in value]

    def process_result_value(self, value, dialect):
        if value is None or dialect.name == "postgresql":
            return value
        if isinstance(self.item_type, UUID):
            return [uuid.UUID(v) for v in value]
        return value
