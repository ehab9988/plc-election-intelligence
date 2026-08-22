"""Seeds a minimal but complete vertical slice: one election, its verified
2026 rule set, a handful of parties/lists/candidates with explicit
registration status, one pollster, and the August 2026 PCPSR poll fixture
described in spec section 51 — then runs and publishes a forecast.

TEST/SEED DATA ONLY. The PCPSR figures below are a fixture for development
and demos, cited to the original poll per section 51; they must be
replaced/supplemented by real ingested polls before any production launch.
This script could not be executed in this repository's development
sandbox (no working Python runtime available — see README "What could not
be verified"). Run it with:

    cd services/api
    python -m pip install -r requirements.txt
    alembic upgrade head
    python ../../scripts/seed_data.py
"""

from __future__ import annotations

import sys
from datetime import UTC, date, datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "services" / "api"))

from app.db import SessionLocal, engine
from app.models import (
    Base,
    Candidate,
    CoalitionEvidence,
    Election,
    ElectionRuleSetORM,
    ElectionTimelineEvent,
    ElectoralList,
    ElectoralListParty,
    Party,
    Person,
    Poll,
    PollQuestion,
    PollResult,
    Pollster,
    Source,
)
from app.models.enums import (
    PollMode,
    PollPopulation,
    RegistrationStatus,
    SourceTier,
    SourceType,
    VerificationConfidence,
)
from app.services.forecast_runner import run_and_persist_forecast
from sqlalchemy.orm import Session


def seed(db: Session) -> None:
    Base.metadata.create_all(bind=engine)

    cec_source = Source(
        name="Palestinian Central Elections Commission",
        source_type=SourceType.OFFICIAL_CEC,
        tier=SourceTier.TIER_1_PRIMARY,
        url="https://www.elections.ps",
        publisher="CEC",
        active=True,
    )
    pcpsr_source = Source(
        name="Palestinian Center for Policy and Survey Research (PCPSR)",
        source_type=SourceType.POLLSTER,
        tier=SourceTier.TIER_2_POLLSTER,
        url="https://www.pcpsr.org",
        publisher="PCPSR",
        active=True,
    )
    db.add_all([cec_source, pcpsr_source])
    db.flush()

    election = Election(
        name_en="2026 Palestinian Legislative Council Election",
        name_ar="انتخابات المجلس التشريعي الفلسطيني 2026",
        election_type="legislative",
        scheduled_date=date(2026, 11, 28),
        is_current=True,
        status="scheduled",
    )
    db.add(election)
    db.flush()

    rule_set = ElectionRuleSetORM(
        election_id=election.id,
        version="1.0.0",
        effective_from=datetime(2026, 1, 1, tzinfo=UTC),
        electoral_system="Nationwide closed-list proportional representation",
        district_structure="Single national constituency",
        total_seats=132,
        threshold_fraction=0.01,
        allocation_method="sainte_lague",
        reserved_seats=[
            {
                "category": "Christian",
                "count": 7,
                "verified": False,
                "mechanism_description": (
                    "At least seven PLC seats allocated to Christian citizens "
                    "under the relevant decree; mechanism pending full-text "
                    "legal confirmation."
                ),
            }
        ],
        gender_quota={"minimum_fraction": 0.33, "description": "At least 33% women on candidate lists."},
        minimum_candidate_age=23,
        allows_individual_candidate_votes=False,
        source_document="CEC / Palestinian election law — baseline captured August 2026",
        verified_at=datetime(2026, 8, 1, tzinfo=UTC),
    )
    db.add(rule_set)

    db.add_all(
        [
            ElectionTimelineEvent(
                election_id=election.id,
                milestone="election_day",
                label_en="Election Day",
                label_ar="يوم الانتخابات",
                starts_at=datetime(2026, 11, 28, tzinfo=UTC),
                ends_at=datetime(2026, 11, 28, tzinfo=UTC),
                source_id=cec_source.id,
            ),
        ]
    )

    # --- Parties / lists -------------------------------------------------
    fatah = Party(
        name_ar="حركة فتح",
        name_en="Fatah Movement",
        abbreviation="Fatah",
        registration_status=RegistrationStatus.ANNOUNCED_INTENTION,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    hamas = Party(
        name_ar="حركة المقاومة الإسلامية - حماس",
        name_en="Islamic Resistance Movement (Hamas)",
        abbreviation="Hamas",
        registration_status=RegistrationStatus.ANNOUNCED_INTENTION,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    third_way = Party(
        name_ar="الطريق الثالث",
        name_en="Third Way",
        abbreviation="TW",
        registration_status=RegistrationStatus.CONSIDERING,
        verification_confidence=VerificationConfidence.LOW,
    )
    # Real, sourced coalition-context parties (not fabricated) — from Al
    # Jazeera's Aug 19, 2026 report "Palestinian factions explore broad
    # alliance for November elections"
    # (https://www.aljazeera.com/news/2026/8/19/palestinian-factions-explore-broad-alliance-for-november-elections),
    # retrieved via web search on 2026-08-22. registration_status is
    # CONSIDERING because no list had been formally submitted to the CEC
    # at time of writing, only alliance exploration reported in the press.
    pij = Party(
        name_ar="حركة الجهاد الإسلامي في فلسطين",
        name_en="Palestinian Islamic Jihad",
        abbreviation="PIJ",
        registration_status=RegistrationStatus.CONSIDERING,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    pflp = Party(
        name_ar="الجبهة الشعبية لتحرير فلسطين",
        name_en="Popular Front for the Liberation of Palestine",
        abbreviation="PFLP",
        registration_status=RegistrationStatus.CONSIDERING,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    national_initiative = Party(
        name_ar="المبادرة الوطنية الفلسطينية",
        name_en="National Initiative",
        abbreviation="Al-Mubadara",
        registration_status=RegistrationStatus.CONSIDERING,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    democratic_reform = Party(
        name_ar="تيار الإصلاح الديمقراطي",
        name_en="Democratic Reform",
        abbreviation="Dahlan faction",
        description_en="Breakaway Fatah faction led by Mohammed Dahlan; local leader Osama al-Farra.",
        registration_status=RegistrationStatus.CONSIDERING,
        verification_confidence=VerificationConfidence.MEDIUM,
    )
    db.add_all([fatah, hamas, third_way, pij, pflp, national_initiative, democratic_reform])
    db.flush()

    aljazeera_source = Source(
        name="Al Jazeera — Palestinian factions explore broad alliance for November elections",
        source_type=SourceType.NEWS_ORGANIZATION,
        tier=SourceTier.TIER_3_NEWS,
        url="https://www.aljazeera.com/news/2026/8/19/palestinian-factions-explore-broad-alliance-for-november-elections",
        publisher="Al Jazeera",
        active=True,
    )
    db.add(aljazeera_source)
    db.flush()

    db.add_all(
        [
            CoalitionEvidence(
                party_a_id=fatah.id,
                party_b_id=hamas.id,
                evidence_type="conflicting",
                statement_summary='Fatah spokesperson Munther al-Hayek: "organisational bases of the Fatah '
                'movement refuse to participate with Hamas in a single list while the door remains open to '
                'alliances with the rest of the factions."',
                statement_date=date(2026, 8, 19),
                source_id=aljazeera_source.id,
                confidence=VerificationConfidence.HIGH,
            ),
            CoalitionEvidence(
                party_a_id=hamas.id,
                party_b_id=pij.id,
                evidence_type="supporting",
                statement_summary="Hamas held meetings with Palestinian Islamic Jihad on a broad electoral "
                'alliance. Hamas official Husam Badran: "We do not need permission or a guarantee from any '
                'party to participate in the Palestinian elections."',
                statement_date=date(2026, 8, 19),
                source_id=aljazeera_source.id,
                confidence=VerificationConfidence.MEDIUM,
            ),
            CoalitionEvidence(
                party_a_id=hamas.id,
                party_b_id=pflp.id,
                evidence_type="supporting",
                statement_summary="Hamas held meetings with the PFLP on a broad electoral alliance.",
                statement_date=date(2026, 8, 19),
                source_id=aljazeera_source.id,
                confidence=VerificationConfidence.MEDIUM,
            ),
            CoalitionEvidence(
                party_a_id=hamas.id,
                party_b_id=national_initiative.id,
                evidence_type="supporting",
                statement_summary="Hamas held meetings with the National Initiative on a broad electoral alliance.",
                statement_date=date(2026, 8, 19),
                source_id=aljazeera_source.id,
                confidence=VerificationConfidence.MEDIUM,
            ),
            CoalitionEvidence(
                party_a_id=hamas.id,
                party_b_id=democratic_reform.id,
                evidence_type="supporting",
                statement_summary="Democratic Reform leader Osama al-Farra confirmed Dahlan's faction decided "
                'to participate, favoring a "broad national alliance" comprising factions, professionals, and '
                "community figures.",
                statement_date=date(2026, 8, 19),
                source_id=aljazeera_source.id,
                confidence=VerificationConfidence.MEDIUM,
            ),
        ]
    )

    lists_spec = [
        (fatah, "قائمة فتح", "Fatah List", "#FDB913"),
        (hamas, "قائمة التغيير والإصلاح", "Change and Reform List", "#00843D"),
        (third_way, "قائمة الطريق الثالث", "Third Way List", "#4472C4"),
    ]
    electoral_lists: dict[str, ElectoralList] = {}
    for party, name_ar, name_en, color in lists_spec:
        el = ElectoralList(
            election_id=election.id,
            list_name_ar=name_ar,
            list_name_en=name_en,
            registration_status=RegistrationStatus.ANNOUNCED_INTENTION
            if party is not third_way
            else RegistrationStatus.CONSIDERING,
            color_hex=color,
        )
        db.add(el)
        db.flush()
        db.add(ElectoralListParty(electoral_list_id=el.id, party_id=party.id))
        electoral_lists[party.abbreviation] = el

    # A handful of candidates per list so the candidate-probability
    # vertical slice has something to display.
    for abbr, list_row in electoral_lists.items():
        for rank in range(1, 16):
            person = Person(
                full_name_ar=f"مرشح {abbr} رقم {rank}",
                full_name_en=f"{abbr} Candidate #{rank}",
                verification_confidence=VerificationConfidence.LOW,
            )
            db.add(person)
            db.flush()
            db.add(
                Candidate(
                    person_id=person.id,
                    electoral_list_id=list_row.id,
                    list_rank=rank,
                    candidate_status="listed",
                )
            )

    # --- PCPSR August 2026 poll fixture (spec section 51) ----------------
    pcpsr = Pollster(
        name_en="Palestinian Center for Policy and Survey Research",
        name_ar="المركز الفلسطيني للبحوث السياسية والمسحية",
        abbreviation="PCPSR",
    )
    db.add(pcpsr)
    db.flush()

    poll = Poll(
        pollster_id=pcpsr.id,
        election_id=election.id,
        sponsor=None,
        source_id=pcpsr_source.id,
        publication_date=date(2026, 8, 10),
        fieldwork_start=date(2026, 8, 5),
        fieldwork_end=date(2026, 8, 8),
        sample_size=1270,
        margin_of_error=3.0,
        methodology_notes="See PCPSR release for full methodology.",
        mode=PollMode.FACE_TO_FACE,
        geographic_population="West Bank and Gaza Strip",
        population=PollPopulation.LIKELY_VOTERS,
        manually_verified=True,
        import_timestamp=datetime.now(UTC),
    )
    db.add(poll)
    db.flush()

    question = PollQuestion(
        poll_id=poll.id,
        question_text_ar="لو أجريت الانتخابات التشريعية اليوم لمن كنت تعطي صوتك؟",
        question_text_en="If legislative elections were held today, which list would you vote for?",
        question_language="ar",
        question_type="vote_choice_if_today",
    )
    db.add(question)
    db.flush()

    # TEST/SEED figures per spec section 51 (Fatah 32%, Hamas 29%, third
    # parties combined 18%, undecided 21%). Split "third parties" evenly
    # across the one third-party list we seeded for simplicity.
    db.add_all(
        [
            PollResult(poll_question_id=question.id, electoral_list_id=electoral_lists["Fatah"].id,
                       label="Fatah List", raw_response_pct=32.0, normalized_pct=32.0),
            PollResult(poll_question_id=question.id, electoral_list_id=electoral_lists["Hamas"].id,
                       label="Change and Reform List", raw_response_pct=29.0, normalized_pct=29.0),
            PollResult(poll_question_id=question.id, electoral_list_id=electoral_lists["TW"].id,
                       label="Third Way List", raw_response_pct=18.0, normalized_pct=18.0),
            PollResult(poll_question_id=question.id, electoral_list_id=None,
                       label="undecided", raw_response_pct=21.0, normalized_pct=21.0),
        ]
    )

    db.commit()

    run = run_and_persist_forecast(
        db,
        election_id=election.id,
        n_simulations=20000,
        random_seed=20260822,
        change_summary="Initial seeded forecast from the August 2026 PCPSR fixture.",
    )
    from app.models.enums import ForecastRunStatus

    run.status = ForecastRunStatus.PUBLISHED
    run.published_at = datetime.now(UTC)
    db.commit()

    print(f"Seeded election {election.id}, forecast run {run.id}")


if __name__ == "__main__":
    session = SessionLocal()
    try:
        seed(session)
    finally:
        session.close()
