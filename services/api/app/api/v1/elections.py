from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...db import get_db
from ...models import Election, ElectionRuleSetORM, ElectionTimelineEvent
from ...schemas.election import ElectionOut, ElectionRuleSetOut, TimelineEventOut

router = APIRouter(prefix="/elections", tags=["elections"])


@router.get("/current", response_model=ElectionOut)
def get_current_election(db: Session = Depends(get_db)) -> Election:
    election = db.scalar(select(Election).where(Election.is_current.is_(True)))
    if election is None:
        raise HTTPException(404, "No current election configured")
    return election


@router.get("/{election_id}", response_model=ElectionOut)
def get_election(election_id: uuid.UUID, db: Session = Depends(get_db)) -> Election:
    election = db.get(Election, election_id)
    if election is None:
        raise HTTPException(404, "Election not found")
    return election


@router.get("/{election_id}/timeline", response_model=list[TimelineEventOut])
def get_election_timeline(election_id: uuid.UUID, db: Session = Depends(get_db)) -> list[ElectionTimelineEvent]:
    stmt = (
        select(ElectionTimelineEvent)
        .where(ElectionTimelineEvent.election_id == election_id)
        .order_by(ElectionTimelineEvent.starts_at)
    )
    return list(db.scalars(stmt))


@router.get("/{election_id}/rules", response_model=ElectionRuleSetOut)
def get_election_rules(election_id: uuid.UUID, db: Session = Depends(get_db)) -> ElectionRuleSetORM:
    """Returns the currently-active rule set for the election, i.e. the
    one with the latest effective_from that has no effective_until, or
    whose window contains "now". Never a hard-coded rule literal (section 3)."""
    stmt = (
        select(ElectionRuleSetORM)
        .where(ElectionRuleSetORM.election_id == election_id)
        .order_by(ElectionRuleSetORM.effective_from.desc())
        .limit(1)
    )
    rules = db.scalar(stmt)
    if rules is None:
        raise HTTPException(404, "No rule set configured for this election")
    return rules
