import 'rule_set.dart';

/// Result of allocating [totalSeats] proportionally across lists.
class SeatAllocationResult {
  /// Seats won per list id. Every key passed in as a candidate list
  /// appears here, including lists that won zero seats.
  final Map<String, int> seatsByList;

  /// List ids excluded from allocation because their vote share fell
  /// below [ElectionRuleSet.thresholdFraction].
  final Set<String> belowThreshold;

  /// True if two or more lists tied on the deciding quotient for at least
  /// one seat during allocation. The law's tie-break procedure has not
  /// been confirmed from official text, so ties are broken deterministically
  /// (by list id) and flagged here rather than silently resolved.
  final bool tieOccurred;

  final int totalSeatsAllocated;

  const SeatAllocationResult({
    required this.seatsByList,
    required this.belowThreshold,
    required this.tieOccurred,
    required this.totalSeatsAllocated,
  });
}

/// Divisor for seat index [seatsWonSoFar] (0-based) under the standard
/// Sainte-Laguë ("odd numbers") sequence: 1, 3, 5, 7, ...
double _standardDivisor(int seatsWonSoFar) => (2 * seatsWonSoFar + 1).toDouble();

/// Divisor for the "modified" Sainte-Laguë sequence used by some countries
/// to make it harder for very small lists to win a first seat: 1.4, 3, 5, 7, ...
double _modifiedDivisor(int seatsWonSoFar) => seatsWonSoFar == 0 ? 1.4 : _standardDivisor(seatsWonSoFar);

/// Allocates [rules.generalPoolSeats] seats across [votesByList] using the
/// highest-averages Sainte-Laguë method specified by [rules].
///
/// This function is deliberately pure and deterministic: given the same
/// votes and rule set it always returns the same result, which is required
/// for forecast reproducibility (a Monte Carlo simulation calls this many
/// thousands of times per run).
///
/// Lists whose vote share is strictly below [ElectionRuleSet.thresholdFraction]
/// are excluded from the allocation pool entirely (they receive zero seats)
/// but their votes still count toward total valid votes when computing
/// vote shares, matching how PR thresholds normally operate.
SeatAllocationResult allocateSeatsSainteLague({
  required Map<String, int> votesByList,
  required ElectionRuleSet rules,
}) {
  if (rules.allocationMethod != AllocationMethod.sainteLague &&
      rules.allocationMethod != AllocationMethod.modifiedSainteLague) {
    throw UnsupportedError(
      'allocateSeatsSainteLague only supports sainteLague/modifiedSainteLague; '
      'rule set ${rules.id} specifies ${rules.allocationMethod}.',
    );
  }

  final divisorFn =
      rules.allocationMethod == AllocationMethod.modifiedSainteLague ? _modifiedDivisor : _standardDivisor;

  final totalVotes = votesByList.values.fold<int>(0, (a, b) => a + b);
  final seats = <String, int>{for (final id in votesByList.keys) id: 0};
  final belowThreshold = <String>{};

  if (totalVotes <= 0) {
    return SeatAllocationResult(
      seatsByList: seats,
      belowThreshold: votesByList.keys.toSet(),
      tieOccurred: false,
      totalSeatsAllocated: 0,
    );
  }

  final eligible = <String>[];
  for (final entry in votesByList.entries) {
    final share = entry.value / totalVotes;
    if (share < rules.thresholdFraction) {
      belowThreshold.add(entry.key);
    } else {
      eligible.add(entry.key);
    }
  }

  final seatsToAllocate = rules.generalPoolSeats;
  bool tieOccurred = false;

  for (var seatIndex = 0; seatIndex < seatsToAllocate; seatIndex++) {
    if (eligible.isEmpty) break;

    String? winner;
    double bestQuotient = -1;
    var tiedThisRound = false;

    // Deterministic order (sorted list ids) so ties break the same way
    // every run, which matters for reproducibility across simulations.
    final ordered = [...eligible]..sort();
    for (final listId in ordered) {
      final quotient = votesByList[listId]! / divisorFn(seats[listId]!);
      if (quotient > bestQuotient) {
        bestQuotient = quotient;
        winner = listId;
        tiedThisRound = false;
      } else if (quotient == bestQuotient) {
        tiedThisRound = true;
      }
    }

    if (tiedThisRound) tieOccurred = true;
    seats[winner!] = seats[winner]! + 1;
  }

  final allocated = seats.values.fold<int>(0, (a, b) => a + b);

  return SeatAllocationResult(
    seatsByList: seats,
    belowThreshold: belowThreshold,
    tieOccurred: tieOccurred,
    totalSeatsAllocated: allocated,
  );
}
