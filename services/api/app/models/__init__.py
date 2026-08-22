"""SQLAlchemy ORM models — see docs/DATA_MODEL.md for an ER-level overview.

Importing this package registers every table on `Base.metadata`, which is
what Alembic's autogenerate and `Base.metadata.create_all` rely on.
"""

from .base import Base
from .auth import ApiKey, AuditLog, Notification, Subscription, User
from .coalition import CoalitionEvidence, CoalitionScenario
from .electoral import Candidate, CandidateRanking, ElectoralList, ElectoralListParty
from .election import Election, ElectionRuleSetORM, ElectionTimelineEvent
from .forecast import (
    ForecastCandidateResult,
    ForecastDistribution,
    ForecastPartyResult,
    ForecastRun,
    SimulationsSummary,
)
from .geo import GeographicArea
from .news import Article, ArticleEntity, NewsSource, PoliticalEvent
from .party import (
    Party,
    PartyAlias,
    PartyPartyRelationship,
    PartyPersonRelationship,
    Person,
    PersonAlias,
)
from .polling import Poll, PollGeographicResult, Pollster, PollsterRating, PollQuestion, PollResult
from .provenance import Citation, EntityConflict, Source

__all__ = [
    "Base",
    "ApiKey",
    "AuditLog",
    "Notification",
    "Subscription",
    "User",
    "CoalitionEvidence",
    "CoalitionScenario",
    "Candidate",
    "CandidateRanking",
    "ElectoralList",
    "ElectoralListParty",
    "Election",
    "ElectionRuleSetORM",
    "ElectionTimelineEvent",
    "ForecastCandidateResult",
    "ForecastDistribution",
    "ForecastPartyResult",
    "ForecastRun",
    "SimulationsSummary",
    "GeographicArea",
    "Article",
    "ArticleEntity",
    "NewsSource",
    "PoliticalEvent",
    "Party",
    "PartyAlias",
    "PartyPartyRelationship",
    "PartyPersonRelationship",
    "Person",
    "PersonAlias",
    "Poll",
    "PollGeographicResult",
    "Pollster",
    "PollsterRating",
    "PollQuestion",
    "PollResult",
    "Citation",
    "EntityConflict",
    "Source",
]
