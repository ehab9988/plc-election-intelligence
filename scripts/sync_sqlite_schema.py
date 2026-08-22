"""Adds any model columns missing from an already-existing database file
— a lightweight substitute for a real migration tool on the static-
GitHub deployment path, where the database is a SQLite file committed
to the repo (data/.state/plc_election.db) and evolves across code
changes over time with nobody running `alembic upgrade head` in
between. `Base.metadata.create_all()` (used at first-seed time — see
seed_data.py) only creates missing TABLES; it silently no-ops on an
existing table even if the model gained a new column since that table
was created. This is what caused export_static_data.py to fail with
"no such column: coalition_evidence.implies_joint_list" after that
column was added to the model post-deployment.

Only ADDs missing columns (SQLite's native `ALTER TABLE ... ADD
COLUMN`) — never drops, renames, or alters an existing column. Safe to
run on every workflow tick: a no-op once the schema is current. This is
NOT a substitute for Alembic on the real-Postgres deployment path
(docs/DEPLOYMENT.md, docs/FREE_TIER_DEPLOYMENT.md) — that path still
needs a real migration when production data with real schema history is
on the line. This script exists because the static-GitHub path's
"database" is disposable fixture-scale data with no such history to
carefully preserve.

Usage:
    DATABASE_URL=sqlite:///./dev.db python scripts/sync_sqlite_schema.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "api"))

from app.db import engine
from app.models import Base
from sqlalchemy import inspect, text


def _sql_literal(value: object) -> str | None:
    """Best-effort Python value -> SQL literal for a DEFAULT clause.
    Returns None for anything not confidently representable, so the
    caller can fall back to adding the column without NOT NULL rather
    than emit incorrect SQL."""
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    if value is None:
        return "NULL"
    return None


def sync_schema() -> list[str]:
    added: list[str] = []
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.begin() as conn:
        for table in Base.metadata.sorted_tables:
            if table.name not in existing_tables:
                continue  # a brand-new table: create_all() already handles this
            existing_columns = {c["name"] for c in inspector.get_columns(table.name)}
            for column in table.columns:
                if column.name in existing_columns:
                    continue

                ddl_type = column.type.compile(dialect=engine.dialect)
                default_literal = None
                if column.default is not None and getattr(column.default, "is_scalar", False):
                    default_literal = _sql_literal(column.default.arg)

                parts = [f'ALTER TABLE "{table.name}" ADD COLUMN "{column.name}" {ddl_type}']
                if default_literal is not None:
                    parts.append(f"DEFAULT {default_literal}")
                    if not column.nullable:
                        parts.append("NOT NULL")
                # else: no derivable default — add it nullable even if the
                # model says NOT NULL, rather than fail the ALTER outright
                # (SQLite refuses NOT NULL ADD COLUMN with no default on a
                # non-empty table).

                conn.execute(text(" ".join(parts)))
                added.append(f"{table.name}.{column.name}")

    return added


if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    added = sync_schema()
    print("Added columns: " + ", ".join(added) if added else "Schema already up to date.")
