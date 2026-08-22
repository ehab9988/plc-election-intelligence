from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...db import get_db
from ...models import Candidate, ElectoralList, Party, Person
from ...schemas.party import CandidateDetailOut, CandidateOut, ElectoralListOut, PartyOut, PersonOut

router = APIRouter(tags=["parties"])


@router.get("/parties", response_model=list[PartyOut])
def list_parties(
    q: str | None = Query(None, description="Search Arabic/English name or abbreviation"),
    db: Session = Depends(get_db),
) -> list[Party]:
    stmt = select(Party)
    if q:
        like = f"%{q}%"
        stmt = stmt.where((Party.name_ar.ilike(like)) | (Party.name_en.ilike(like)) | (Party.abbreviation.ilike(like)))
    return list(db.scalars(stmt.order_by(Party.name_en)))


@router.get("/parties/{party_id}", response_model=PartyOut)
def get_party(party_id: uuid.UUID, db: Session = Depends(get_db)) -> Party:
    party = db.get(Party, party_id)
    if party is None:
        raise HTTPException(404, "Party not found")
    return party


@router.get("/electoral-lists", response_model=list[ElectoralListOut])
def list_electoral_lists(
    election_id: uuid.UUID | None = None,
    db: Session = Depends(get_db),
) -> list[ElectoralList]:
    stmt = select(ElectoralList)
    if election_id:
        stmt = stmt.where(ElectoralList.election_id == election_id)
    return list(db.scalars(stmt))


@router.get("/candidates", response_model=list[CandidateOut])
def list_candidates(
    electoral_list_id: uuid.UUID | None = None,
    db: Session = Depends(get_db),
) -> list[Candidate]:
    stmt = select(Candidate)
    if electoral_list_id:
        stmt = stmt.where(Candidate.electoral_list_id == electoral_list_id)
    return list(db.scalars(stmt.order_by(Candidate.list_rank)))


@router.get("/candidates/{candidate_id}", response_model=CandidateDetailOut)
def get_candidate(candidate_id: uuid.UUID, db: Session = Depends(get_db)) -> CandidateDetailOut:
    candidate = db.get(Candidate, candidate_id)
    if candidate is None:
        raise HTTPException(404, "Candidate not found")
    person = db.get(Person, candidate.person_id)
    electoral_list = db.get(ElectoralList, candidate.electoral_list_id)

    # Seat probability is intentionally NOT joined here from a hard-coded
    # forecast — the /forecast/{run_id}/candidates endpoint is the source
    # of truth so the number always carries a model_version + data cutoff.
    return CandidateDetailOut(
        candidate=CandidateOut.model_validate(candidate),
        person=PersonOut.model_validate(person),
        electoral_list=ElectoralListOut.model_validate(electoral_list),
    )
