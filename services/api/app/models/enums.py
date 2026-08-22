"""Enumerations shared across the schema. Kept as plain Python Enums backed
by Postgres native enums for readability in psql/admin tooling.
"""

from __future__ import annotations

import enum


class RegistrationStatus(str, enum.Enum):
    """See spec section 5 — never mark a list officially_approved without
    a CEC citation."""

    RUMORED = "rumored"
    CONSIDERING = "considering"
    ANNOUNCED_INTENTION = "announced_intention"
    SUBMITTED_REGISTRATION = "submitted_registration"
    PROVISIONAL = "provisional"
    OFFICIALLY_APPROVED = "officially_approved"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"
    DISQUALIFIED = "disqualified"


class SourceTier(str, enum.Enum):
    TIER_1_PRIMARY = "tier_1_primary"
    TIER_2_POLLSTER = "tier_2_pollster"
    TIER_3_NEWS = "tier_3_news"
    TIER_4_OTHER = "tier_4_other"


class SourceType(str, enum.Enum):
    OFFICIAL_CEC = "official_cec"
    OFFICIAL_LAW = "official_law"
    OFFICIAL_PARTY = "official_party"
    POLLSTER = "pollster"
    NEWS_ORGANIZATION = "news_organization"
    SOCIAL_MEDIA = "social_media"
    ADMIN_ENTERED = "admin_entered"
    OTHER = "other"


class VerificationConfidence(str, enum.Enum):
    VERY_HIGH = "very_high"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    UNVERIFIED = "unverified"


class RelationshipType(str, enum.Enum):
    MEMBER_OF = "member_of"
    AFFILIATED_WITH = "affiliated_with"
    ELECTORAL_LIST_OF = "electoral_list_of"
    COALITION_WITH = "coalition_with"
    SPLIT_FROM = "split_from"
    LED_BY = "led_by"
    ENDORSED_BY = "endorsed_by"
    HISTORICAL_AFFILIATION = "historical_affiliation"


class PollPopulation(str, enum.Enum):
    ALL_ADULTS = "all_adults"
    REGISTERED_VOTERS = "registered_voters"
    LIKELY_VOTERS = "likely_voters"


class PollMode(str, enum.Enum):
    FACE_TO_FACE = "face_to_face"
    PHONE = "phone"
    ONLINE = "online"
    MIXED = "mixed"
    UNKNOWN = "unknown"  # source did not report a mode — never guess one (e.g. AI-discovered draft polls)


class UserRole(str, enum.Enum):
    USER = "user"
    PREMIUM = "premium"
    ANALYST = "analyst"
    EDITOR = "editor"
    ADMINISTRATOR = "administrator"


class EventCategory(str, enum.Enum):
    PARTY_ALLIANCE = "party_alliance"
    CANDIDATE_WITHDRAWAL = "candidate_withdrawal"
    LEADERSHIP_CHANGE = "leadership_change"
    ENDORSEMENT = "endorsement"
    LEGAL_CHANGE = "legal_change"
    CANDIDATE_DISQUALIFICATION = "candidate_disqualification"
    LIST_REGISTRATION = "list_registration"
    CEASEFIRE_WAR_DEVELOPMENT = "ceasefire_war_development"
    CORRUPTION_ALLEGATION = "corruption_allegation"
    ECONOMIC_EVENT = "economic_event"
    CAMPAIGN_LAUNCH = "campaign_launch"
    POLLING_SHOCK = "polling_shock"
    OTHER = "other"


class ForecastRunStatus(str, enum.Enum):
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PUBLISHED = "published"
    REVERTED = "reverted"


class UndecidedAllocationMethod(str, enum.Enum):
    PROPORTIONAL = "proportional"
    HISTORICAL_PARTISAN = "historical_partisan"
    DEMOGRAPHIC = "demographic"
    MONTE_CARLO_BREAK = "monte_carlo_break"
