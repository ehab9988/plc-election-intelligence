"""SQLAlchemy ORM models — see docs/DATA_MODEL.md for an ER-level overview.

Importing this package registers every table on `Base.metadata`, which is
what Alembic's autogenerate and `Base.metadata.create_all` rely on.
"""

from .auth import ApiKey, AuditLog, Notification, Subscription, User
from .base import Base
from .coalition import CoalitionEvidence, CoalitionFormationEstimate, CoalitionScenario
from .election import Election, ElectionRuleSetORM, ElectionTimelineEvent
from .electoral import Candidate, CandidateRanking, ElectoralList, ElectoralListParty
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
from .polling import (
    Poll,
    PollGeographicResult,
    PollQuestion,
    PollResult,
    Pollster,
    PollsterRating,
)
from .provenance import Citation, EntityConflict, Source

__all__ = [
    "ApiKey",
    "Article",
    "ArticleEntity",
    "AuditLog",
    "Base",
    "Candidate",
    "CandidateRanking",
    "Citation",
    "CoalitionEvidence",
    "CoalitionFormationEstimate",
    "CoalitionScenario",
    "Election",
    "ElectionRuleSetORM",
    "ElectionTimelineEvent",
    "ElectoralList",
    "ElectoralListParty",
    "EntityConflict",
    "ForecastCandidateResult",
    "ForecastDistribution",
    "ForecastPartyResult",
    "ForecastRun",
    "GeographicArea",
    "NewsSource",
    "Notification",
    "Party",
    "PartyAlias",
    "PartyPartyRelationship",
    "PartyPersonRelationship",
    "Person",
    "PersonAlias",
    "PoliticalEvent",
    "Poll",
    "PollGeographicResult",
    "PollQuestion",
    "PollResult",
    "Pollster",
    "PollsterRating",
    "SimulationsSummary",
    "Source",
    "Subscription",
    "User",
]
