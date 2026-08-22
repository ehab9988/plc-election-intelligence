import 'package:election_rules/election_rules.dart';
import 'package:test/test.dart';

void main() {
  group('candidateSeatProbability', () {
    test('all probabilities are within [0, 1]', () {
      final sims = List<int>.generate(1000, (i) => i % 30);
      for (var rank = 1; rank <= 40; rank++) {
        final p = candidateSeatProbability(rank: rank, partySeatSimulations: sims);
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });

    test('rank 1 probability >= any higher rank probability (monotonic non-increasing)', () {
      final sims = [5, 10, 15, 20, 3, 8, 12, 30, 1, 0];
      final probs = candidateSeatProbabilitiesForList(listSize: 35, partySeatSimulations: sims);
      for (var i = 1; i < probs.length; i++) {
        expect(probs[i], lessThanOrEqualTo(probs[i - 1]),
            reason: 'probability(rank ${i + 1}) must not exceed probability(rank $i)');
      }
    });

    test('candidate #10 cannot have lower probability than #11 on the same list (acceptance test #79)', () {
      final sims = List<int>.generate(5000, (i) => (i * 37) % 25);
      final probs = candidateSeatProbabilitiesForList(listSize: 25, partySeatSimulations: sims);
      expect(probs[9], greaterThanOrEqualTo(probs[10])); // rank 10 vs rank 11, 0-indexed
    });

    test('rank exceeding max simulated seats has zero probability', () {
      final sims = [1, 2, 3, 2, 1];
      final p = candidateSeatProbability(rank: 20, partySeatSimulations: sims);
      expect(p, 0.0);
    });

    test('rank always achievable has probability 1.0', () {
      final sims = [10, 12, 15, 20];
      final p = candidateSeatProbability(rank: 5, partySeatSimulations: sims);
      expect(p, 1.0);
    });

    test('empty simulations return 0 rather than throwing', () {
      expect(candidateSeatProbability(rank: 1, partySeatSimulations: []), 0.0);
    });

    test('rank < 1 throws ArgumentError', () {
      expect(() => candidateSeatProbability(rank: 0, partySeatSimulations: [1, 2]),
          throwsArgumentError);
    });
  });

  group('coalitionMajorityProbability', () {
    test('probability is consistent with underlying simulation data (acceptance test #79)', () {
      final sims = [
        {'A': 40, 'B': 30, 'C': 62},
        {'A': 35, 'B': 35, 'C': 62},
        {'A': 30, 'B': 30, 'C': 72},
        {'A': 20, 'B': 20, 'C': 92},
      ];
      // A+B >= 67? sims: 70(no,67 exact? 40+30=70>=67 yes),70? recompute
      // sim1: A+B=70>=67 true
      // sim2: A+B=70>=67 true
      // sim3: A+B=60>=67 false
      // sim4: A+B=40>=67 false
      final p = coalitionMajorityProbability(
        coalitionListIds: {'A', 'B'},
        simulations: sims,
        totalSeats: 132,
      );
      expect(p, 0.5);
    });

    test('empty simulations returns 0', () {
      final p = coalitionMajorityProbability(coalitionListIds: {'A'}, simulations: [], totalSeats: 132);
      expect(p, 0.0);
    });

    test('missing list id in a simulation is treated as zero seats, not an error', () {
      final sims = [
        {'A': 67},
        {'B': 100},
      ];
      final p = coalitionMajorityProbability(coalitionListIds: {'A'}, simulations: sims, totalSeats: 132);
      expect(p, 0.5);
    });
  });

  group('SimulationSummary', () {
    test('median/mean/intervals are computed and ordered sensibly', () {
      final values = List<num>.generate(1000, (i) => i.toDouble());
      final summary = SimulationSummary.fromValues(values);
      expect(summary.low95, lessThanOrEqualTo(summary.low80));
      expect(summary.low80, lessThanOrEqualTo(summary.low50));
      expect(summary.low50, lessThanOrEqualTo(summary.median));
      expect(summary.median, lessThanOrEqualTo(summary.high50));
      expect(summary.high50, lessThanOrEqualTo(summary.high80));
      expect(summary.high80, lessThanOrEqualTo(summary.high95));
    });

    test('empty values does not throw', () {
      final summary = SimulationSummary.fromValues(const []);
      expect(summary.median, 0);
    });
  });
}
