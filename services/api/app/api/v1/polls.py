from __future__ import annotations

import uuid
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from ...db import get_db
from ...models import ElectoralList, Poll, PollQuestion, PollResult
from ...schemas.poll import PollingAveragePoint, PollOut

router = APIRouter(tags=["polls"])


@router.get("/polls", response_model=list[PollOut])
def list_polls(election_id: uuid.UUID | None = None, db: Session = Depends(get_db)) -> list[Poll]:
    stmt = select(Poll).options(selectinload(Poll.questions)).order_by(Poll.fieldwork_end.desc())
    if election_id:
        stmt = stmt.where(Poll.election_id == election_id)
    return list(db.scalars(stmt))


@router.get("/polls/{poll_id}", response_model=PollOut)
def get_poll(poll_id: uuid.UUID, db: Session = Depends(get_db)) -> Poll:
    poll = db.get(Poll, poll_id, options=[selectinload(Poll.questions)])
    if poll is None:
        raise HTTPException(404, "Poll not found")
    return poll


@router.get("/polling-average", response_model=list[PollingAveragePoint])
def polling_average(election_id: uuid.UUID, db: Session = Depends(get_db)) -> list[PollingAveragePoint]:
    """Computes the weighted polling average on demand from stored polls.
    See forecasting/polling_average.py for the methodology (section 13)."""
    from forecasting.polling_average import PollObservation, WeightingConfig, compute_polling_average

    stmt = (
        select(Poll)
        .options(selectinload(Poll.questions).selectinload(PollQuestion.results))
        .where(Poll.election_id == election_id)
    )
    polls = list(db.scalars(stmt))

    observations: list[PollObservation] = []
    for poll in polls:
        for question in poll.questions:
            if question.question_type != "vote_choice_if_today":
                continue
            for result in question.results:
                if result.electoral_list_id is None:
                    continue
                observations.append(
                    PollObservation(
                        poll_id=str(poll.id),
                        pollster_id=str(poll.pollster_id),
                        electoral_list_id=str(result.electoral_list_id),
                        pct=result.normalized_pct or result.raw_response_pct,
                        sample_size=poll.sample_size,
                        fieldwork_end=poll.fieldwork_end,
                        population=poll.population.value,
                        pollster_quality_score=70.0,  # TODO: join PollsterRating once ingested
                    )
                )

    averages = compute_polling_average(observations, as_of=date.today(), cfg=WeightingConfig())

    list_names = {
        str(el.id): el.list_name_en
        for el in db.scalars(select(ElectoralList).where(ElectoralList.election_id == election_id))
    }

    return [
        PollingAveragePoint(
            electoral_list_id=uuid.UUID(list_id),
            list_name_en=list_names.get(list_id, "Unknown"),
            weighted_average_pct=avg.weighted_average_pct,
            trend_low=avg.trend_low,
            trend_high=avg.trend_high,
            n_polls_used=avg.n_polls_used,
            most_recent_fieldwork_end=avg.most_recent_fieldwork_end,
        )
        for list_id, avg in averages.items()
    ]
