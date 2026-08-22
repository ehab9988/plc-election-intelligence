"""Deterministic electoral mathematics for PLC Election Intelligence.

This is a direct, line-by-line port of the verified `election_rules` Dart
package (packages/election_rules) — see that package's test suite
(packages/election_rules/test) for the golden/acceptance tests this
algorithm was validated against. Keep the two implementations in sync: any
change to the allocation or probability logic must be made in both places
and re-verified with `dart test` (the only runtime in this repo's
development sandbox that could execute the tests directly).
"""

from .candidate_probability import (
    SimulationSummary,
    candidate_seat_probabilities_for_list,
    candidate_seat_probability,
    coalition_majority_probability,
    majority_threshold,
)
from .rule_set import AllocationMethod, ElectionRuleSet, GenderQuota, ReservedSeatRule
from .sainte_lague import SeatAllocationResult, allocate_seats_sainte_lague

__all__ = [
    "AllocationMethod",
    "ElectionRuleSet",
    "GenderQuota",
    "ReservedSeatRule",
    "SeatAllocationResult",
    "SimulationSummary",
    "allocate_seats_sainte_lague",
    "candidate_seat_probabilities_for_list",
    "candidate_seat_probability",
    "coalition_majority_probability",
    "majority_threshold",
]
