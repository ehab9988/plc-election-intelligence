import 'rule_set.dart';

/// Computes a closed-list candidate's estimated probability of entering
/// parliament from a set of Monte Carlo simulation outcomes.
///
/// Under closed-list PR, a voter votes for the list, not the candidate.
/// A candidate at [rank] (1-based position on the list) wins a seat in a
/// given simulation iff that list's simulated seat count in that
/// iteration is >= [rank]. This is CRITICAL ACCURACY RULE #7's
/// implementation: we never derive this from a fabricated per-candidate
/// vote share.
///
/// [partySeatSimulations] is one simulated seat count per Monte Carlo
/// iteration for the candidate's list (same list, across all iterations
/// of one forecast run).
///
/// Returns a probability in [0, 1]. Callers are responsible for rounding
/// for display (never show more than whole-percent precision — see
/// CRITICAL ACCURACY RULE #9 / section 21).
double candidateSeatProbability({
  required int rank,
  required List<int> partySeatSimulations,
}) {
  if (rank < 1) {
    throw ArgumentError.value(rank, 'rank', 'Candidate list rank must be >= 1');
  }
  if (partySeatSimulations.isEmpty) return 0;

  final winCount = partySeatSimulations.where((seats) => seats >= rank).length;
  return winCount / partySeatSimulations.length;
}

/// Computes candidateSeatProbability for every rank on a list in one pass,
/// guaranteeing the monotonicity property required by the acceptance
/// tests: probability(rank) must never increase as rank increases.
List<double> candidateSeatProbabilitiesForList({
  required int listSize,
  required List<int> partySeatSimulations,
}) {
  if (partySeatSimulations.isEmpty) return List.filled(listSize, 0);
  final n = partySeatSimulations.length;
  // Sort descending once; probability(rank) = count(seats >= rank) / n,
  // which is monotonically non-increasing in rank by construction.
  final sorted = [...partySeatSimulations]..sort();
  return List.generate(listSize, (i) {
    final rank = i + 1;
    // Binary search for first index >= rank in ascending sorted list.
    var lo = 0, hi = sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid] < rank) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final countAtLeastRank = sorted.length - lo;
    return countAtLeastRank / n;
  });
}

/// Majority threshold for a parliament of [totalSeats], never hard-coded
/// as a literal elsewhere in the codebase: floor(totalSeats/2) + 1.
int majorityThreshold(int totalSeats) => (totalSeats ~/ 2) + 1;

/// Probability that the combined seats of [coalitionListIds] meet or
/// exceed the majority threshold, across a set of Monte Carlo simulations.
///
/// [simulations] is a list of per-iteration seat maps (listId -> seats),
/// one map per Monte Carlo iteration, all produced by the same forecast
/// run (see forecasting/monte_carlo.py on the backend for the generator;
/// this function only consumes results, it does not simulate).
double coalitionMajorityProbability({
  required Set<String> coalitionListIds,
  required List<Map<String, int>> simulations,
  required int totalSeats,
}) {
  if (simulations.isEmpty) return 0;
  final threshold = majorityThreshold(totalSeats);
  var hits = 0;
  for (final sim in simulations) {
    final combined = coalitionListIds.fold<int>(0, (sum, id) => sum + (sim[id] ?? 0));
    if (combined >= threshold) hits++;
  }
  return hits / simulations.length;
}

/// Distribution summary (median / mean / credible interval) for a metric
/// (typically seats or vote share) across Monte Carlo iterations.
class SimulationSummary {
  final double median;
  final double mean;
  final double low50;
  final double high50;
  final double low80;
  final double high80;
  final double low95;
  final double high95;

  const SimulationSummary({
    required this.median,
    required this.mean,
    required this.low50,
    required this.high50,
    required this.low80,
    required this.high80,
    required this.low95,
    required this.high95,
  });

  factory SimulationSummary.fromValues(List<num> values) {
    if (values.isEmpty) {
      return const SimulationSummary(
        median: 0, mean: 0, low50: 0, high50: 0, low80: 0, high80: 0, low95: 0, high95: 0,
      );
    }
    final sorted = [...values]..sort();
    double pct(double p) {
      final idx = ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
      return sorted[idx].toDouble();
    }

    final mean = sorted.fold<double>(0, (a, b) => a + b) / sorted.length;
    return SimulationSummary(
      median: pct(0.5),
      mean: mean,
      low50: pct(0.25),
      high50: pct(0.75),
      low80: pct(0.10),
      high80: pct(0.90),
      low95: pct(0.025),
      high95: pct(0.975),
    );
  }
}

/// Named reference to the rule set (re-exported here for convenience so
/// forecast-facing code only needs one import).
typedef ElectionRules = ElectionRuleSet;
