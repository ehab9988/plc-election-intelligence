"""Versioned electoral rule configuration.

Election law can change (amendments, court rulings, CEC clarifications), so
rules are never hard-coded into the allocation algorithms. Instead an
``ElectionRuleSet`` is a data record, valid for a date range, that the
allocation engine consumes. Administrators create a new version rather than
mutating an existing one, so historical forecasts remain reproducible
against the rules that were actually in force at the time.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import Enum


class AllocationMethod(str, Enum):
    """Seat allocation method a rule set may specify.

    Only SAINTE_LAGUE is implemented today because it is the method
    confirmed for the 2026 PLC election. Other members exist so the engine
    can be extended to other Palestinian elections (e.g. local councils)
    without a breaking API change.
    """

    SAINTE_LAGUE = "sainte_lague"
    MODIFIED_SAINTE_LAGUE = "modified_sainte_lague"
    D_HONDT = "d_hondt"


@dataclass(frozen=True)
class ReservedSeatRule:
    """A reserved/quota seat carve-out (e.g. Christian seats).

    Applies only once officially verified in the governing legal text.
    ``count`` seats are set aside for ``category``. Until an admin marks
    ``verified = True``, the seat count is tracked but MUST NOT be
    silently subtracted from the general proportional pool by any
    automated process.
    """

    category: str
    count: int
    mechanism_description: str
    source_document: str
    mechanism_code: str | None = None
    verified: bool = False


@dataclass(frozen=True)
class GenderQuota:
    minimum_fraction: float
    description: str


@dataclass(frozen=True)
class ElectionRuleSet:
    id: str
    election_id: str
    version: str
    effective_from: datetime
    electoral_system: str
    district_structure: str
    total_seats: int
    threshold_fraction: float
    allocation_method: AllocationMethod
    minimum_candidate_age: int
    source_document: str
    verified_at: datetime
    effective_until: datetime | None = None
    reserved_seats: tuple[ReservedSeatRule, ...] = field(default_factory=tuple)
    gender_quota: GenderQuota | None = None
    list_minimum_candidates: int | None = None
    list_maximum_candidates: int | None = None
    allows_individual_candidate_votes: bool = False

    @property
    def majority_threshold(self) -> int:
        """floor(total_seats / 2) + 1. For 132 seats this is 67."""
        return (self.total_seats // 2) + 1

    @property
    def general_pool_seats(self) -> int:
        """total_seats minus legally VERIFIED reserved seats only."""
        return self.total_seats - sum(r.count for r in self.reserved_seats if r.verified)

    def is_active_on(self, date: datetime) -> bool:
        if date < self.effective_from:
            return False
        return not (self.effective_until is not None and date >= self.effective_until)

    @staticmethod
    def plc_2026_baseline(election_id: str) -> ElectionRuleSet:
        """Verified baseline for the 2026 PLC election as of August 2026.

        Reserved seats and the gender quota are modeled but marked
        unverified pending the complete legal mechanism text.
        """
        return ElectionRuleSet(
            id="ruleset-plc-2026-v1",
            election_id=election_id,
            version="1.0.0",
            effective_from=datetime(2026, 1, 1, tzinfo=UTC),
            electoral_system="Nationwide closed-list proportional representation",
            district_structure="Single national constituency",
            total_seats=132,
            threshold_fraction=0.01,
            allocation_method=AllocationMethod.SAINTE_LAGUE,
            minimum_candidate_age=23,
            gender_quota=GenderQuota(
                minimum_fraction=0.33,
                description=(
                    "At least 33% women representation on candidate lists "
                    "under the current amendment to the election law."
                ),
            ),
            reserved_seats=(
                ReservedSeatRule(
                    category="Christian",
                    count=7,
                    mechanism_description=(
                        "At least seven PLC seats allocated to Christian citizens "
                        "under the relevant decree. Exact allocation mechanism "
                        "requires confirmation against the complete legal text "
                        "before being applied automatically."
                    ),
                    source_document=(
                        "Palestinian election law amendment (decree) — pending "
                        "full-text legal citation"
                    ),
                    verified=False,
                ),
            ),
            allows_individual_candidate_votes=False,
            source_document=(
                "Palestinian Central Elections Commission / Palestinian election "
                "law — baseline captured August 2026; supersede via a new "
                "versioned ElectionRuleSet whenever the CEC publishes an update."
            ),
            verified_at=datetime(2026, 8, 1, tzinfo=UTC),
        )
