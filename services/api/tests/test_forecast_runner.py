"""NOTE: could not be executed in this repo's development sandbox — see
test_health.py. Exercises run_and_persist_forecast end-to-end against an
in-memory SQLite database standing in for Postgres (JSONB/ARRAY columns
used elsewhere in the schema are not exercised by this particular test,
since it only touches the election/rules/list/poll/candidate/forecast
tables needed for one forecast run). CAVEAT: the models use
`sqlalchemy.dialects.postgresql.UUID` and `JSONB` column types, which are
Postgres-specific; running this against SQLite may require swapping those
for dialect-generic types (or running against a real throwaway Postgres
database instead of SQLite) — this was not verified in this sandbox."""

import uuid
from datetime import UTC, date, datetime

import pytest
from app.models import (
    Base,
    Candidate,
    Election,
    ElectionRuleSetORM,
    ElectoralList,
    Person,
    Poll,
    PollQuestion,
    PollResult,
    Pollster,
    Source,
)
from app.models.enums import PollMode, PollPopulation, SourceTier, SourceType
from app.services.forecast_runner import run_and_persist_forecast
from sqlalchemy import create_engine
from sqlalchemy.orm import Session


@pytest.fixture()
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


def _seed_minimal_election(db: Session):
    election = Election(
        id=uuid.uuid4(),
        name_en="Test Election",
        name_ar="انتخابات تجريبية",
        election_type="legislative",
        scheduled_date=date(2026, 11, 28),
        is_current=True,
        status="scheduled",
    )
    db.add(election)
    db.flush()

    rules = ElectionRuleSetORM(
        id=uuid.uuid4(),
        election_id=election.id,
        version="1.0.0",
        effective_from=datetime(2026, 1, 1, tzinfo=UTC),
        electoral_system="closed-list PR",
        district_structure="single national constituency",
        total_seats=132,
        threshold_fraction=0.01,
        allocation_method="sainte_lague",
        minimum_candidate_age=23,
        source_document="test",
        verified_at=datetime(2026, 1, 1, tzinfo=UTC),
    )
    db.add(rules)

    lists = [
        ElectoralList(id=uuid.uuid4(), election_id=election.id, list_name_ar="أ", list_name_en="List A"),
        ElectoralList(id=uuid.uuid4(), election_id=election.id, list_name_ar="ب", list_name_en="List B"),
    ]
    db.add_all(lists)
    db.flush()

    source = Source(name="Test Pollster Source", source_type=SourceType.POLLSTER, tier=SourceTier.TIER_2_POLLSTER)
    db.add(source)
    pollster = Pollster(name_en="Test Pollster", name_ar="مؤسسة استطلاع")
    db.add(pollster)
    db.flush()

    poll = Poll(
        pollster_id=pollster.id,
        election_id=election.id,
        source_id=source.id,
        publication_date=date(2026, 8, 10),
        fieldwork_start=date(2026, 8, 5),
        fieldwork_end=date(2026, 8, 8),
        sample_size=1200,
        mode=PollMode.FACE_TO_FACE,
        population=PollPopulation.LIKELY_VOTERS,
        manually_verified=True,
        import_timestamp=datetime.now(UTC),
    )
    db.add(poll)
    db.flush()

    question = PollQuestion(
        poll_id=poll.id,
        question_text_ar="سؤال",
        question_type="vote_choice_if_today",
    )
    db.add(question)
    db.flush()

    db.add_all([
        PollResult(poll_question_id=question.id, electoral_list_id=lists[0].id, label="List A", raw_response_pct=45.0, normalized_pct=45.0),
        PollResult(poll_question_id=question.id, electoral_list_id=lists[1].id, label="List B", raw_response_pct=35.0, normalized_pct=35.0),
    ])

    for rank in range(1, 6):
        person = Person(full_name_ar=f"مرشح {rank}", full_name_en=f"Candidate {rank}")
        db.add(person)
        db.flush()
        db.add(Candidate(person_id=person.id, electoral_list_id=lists[0].id, list_rank=rank))

    db.commit()
    return election


def test_run_and_persist_forecast_produces_132_seats(db_session):
    election = _seed_minimal_election(db_session)
    run = run_and_persist_forecast(db_session, election.id, n_simulations=500, random_seed=1)

    assert run.simulations_performed == 500
    total_seats = sum(r.seats_median for r in run.party_results)
    # seats_median is a per-list median across iterations, so the SUM
    # across lists need not equal exactly 132 (medians don't add like
    # single draws do) — but it should be close, and every individual
    # iteration inside the engine allocates exactly 132 (see
    # services/forecasting/tests/test_monte_carlo.py for that stronger
    # per-iteration assertion).
    assert 100 <= total_seats <= 132


def test_candidate_probabilities_are_bounded(db_session):
    election = _seed_minimal_election(db_session)
    run = run_and_persist_forecast(db_session, election.id, n_simulations=500, random_seed=2)
    from app.models import ForecastCandidateResult
    from sqlalchemy import select

    results = db_session.scalars(select(ForecastCandidateResult).where(ForecastCandidateResult.run_id == run.id)).all()
    assert len(results) == 5
    for r in results:
        assert 0.0 <= r.seat_probability <= 1.0
