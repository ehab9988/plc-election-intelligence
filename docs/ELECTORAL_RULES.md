# Electoral Rules Engine

## Why versioned rules, not constants

Palestinian election law can change (amendments, decrees, CEC
clarifications). Hard-coding "132 seats" or "1% threshold" into the seat
allocation algorithm would make every historical forecast wrong the moment
the law changes, and would require a code deployment to fix. Instead, the
engine reads an `ElectionRuleSet` — a versioned, timestamped, sourced
record — and never assumes a rule that hasn't been verified.

Implementation:
- Dart (client-shareable, tested): `packages/election_rules`
- Python (backend, direct port): `packages/election_rules_py`
- Persisted form: `election_rule_sets` table (`services/api/app/models/election.py`)

## `ElectionRuleSet` fields

See `packages/election_rules/lib/src/rule_set.dart` for the authoritative
field list: `total_seats`, `threshold_fraction`, `allocation_method`,
`reserved_seats` (each with its own `verified` flag), `gender_quota`,
`minimum_candidate_age`, `list_minimum_candidates` /
`list_maximum_candidates`, `allows_individual_candidate_votes`,
`source_document`, `verified_at`.

**Reserved seats are modeled but not auto-applied until verified.** The
August 2026 baseline records "at least 7 Christian seats" per the relevant
decree, but `verified: false` — the exact allocation mechanism (best-loser
top-up vs. dedicated sub-list vs. other) has not been confirmed against
complete legal text. `ElectionRuleSet.generalPoolSeats` only subtracts
seats from `reserved_seats` entries where `verified == true`, so an
unverified reserved-seat rule can be recorded for visibility without
silently distorting the general proportional allocation.

## 2026 PLC baseline (verified as of August 2026)

| Field | Value |
|---|---|
| Total seats | 132 |
| Electoral system | Nationwide closed-list proportional representation |
| District structure | Single national constituency |
| Threshold | 1% of valid votes |
| Allocation method | Sainte-Laguë (standard divisor sequence) |
| Minimum candidate age | 23 |
| Gender quota | ≥33% women per list (unverified mechanism detail) |
| Reserved seats | ≥7 Christian seats (unverified mechanism) |
| Individual candidate votes | Not allowed (closed list) |

Majority threshold is **never** a literal `67` in code — it is always
computed as `floor(total_seats / 2) + 1`. See `majorityThreshold` /
`majority_threshold()` in both engine packages.

## Sainte-Laguë algorithm

Highest-averages method. For each of the `general_pool_seats` seats, in
order, assign it to whichever eligible list currently has the highest
quotient `votes / divisor(seats_won_so_far)`, where the standard divisor
sequence is `1, 3, 5, 7, ...` (`modified_sainte_lague` uses `1.4` as the
first divisor instead of `1`, per the common "modified" variant used by
some countries to disadvantage very small lists on their first seat — only
used if a future `ElectionRuleSet` explicitly specifies it; the 2026
baseline uses the standard sequence).

Lists below `threshold_fraction` of total valid votes are excluded from
the allocation pool (zero seats) but their votes still count toward the
denominator used to compute vote shares.

Ties are broken deterministically (by list id, sorted) rather than
randomly, and flagged (`tie_occurred`) rather than silently resolved,
because the official tie-break procedure has not been confirmed from
complete legal text. **This is a documented placeholder** — do not treat
`tie_occurred` handling as legally authoritative until confirmed.

### Golden test

Hand-traced example (see `packages/election_rules/test/sainte_lague_test.dart`):
votes `A=100000, B=80000, C=30000`, 7 seats, standard divisors.

| Seat # | Divisor row | Winner |
|---|---|---|
| 1 | A/1=100000, B/1=80000, C/1=30000 | A |
| 2 | A/3=33333, B/1=80000, C/1=30000 | B |
| 3 | A/3=33333, B/3=26667, C/1=30000 | A |
| 4 | A/5=20000, B/3=26667, C/1=30000 | C |
| 5 | A/5=20000, B/3=26667, C/3=10000 | B |
| 6 | A/5=20000, B/5=16000, C/3=10000 | A |
| 7 | A/7=14286, B/5=16000, C/3=10000 | B |

Result: A=3, B=3, C=1. This exact sequence is asserted by the test suite
— **24/24 tests pass**, verified in this repository via `dart test`
(see `packages/election_rules/`).

## Candidate seat probability (closed list)

Under closed-list PR, a candidate at list position `rank` wins a seat in a
given Monte Carlo iteration **iff that list's simulated seat count in that
iteration is `>= rank`**. Probability = fraction of iterations where this
holds. This is the only mechanism used anywhere in the codebase to
estimate a candidate's chance of winning a seat — there is no code path
that computes or stores an individual candidate vote share (CRITICAL
ACCURACY RULE #7). See `candidate_seat_probability` /
`candidate_seat_probabilities_for_list` in both engine packages, and their
tests asserting monotonicity (`probability(rank) `never increases as
`rank` increases`).

## Extending to other elections

`ElectionRuleSet.allocation_method` and `district_structure` are
discriminators specifically so the same engine can support a future local
elections module with different rules (e.g. district-based, individual
candidate votes allowed) without a rewrite — see
`allows_individual_candidate_votes`, which gates whether any UI/API code
path is even allowed to compute per-candidate vote shares.
