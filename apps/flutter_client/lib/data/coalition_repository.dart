import '../core/api_client.dart';
import '../models/coalition.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class CoalitionRepository {
  final ApiClient _client;
  final bool demoMode;

  CoalitionRepository(this._client, {required this.demoMode});

  Future<List<CoalitionEvidence>> listEvidence({String? partyId}) async {
    if (demoMode) return fixture.demoCoalitionEvidence.map(CoalitionEvidence.fromJson).toList();
    try {
      final res = await _client.dio.get('/coalitions', queryParameters: {'party_id': ?partyId});
      return (res.data as List<dynamic>).map((e) => CoalitionEvidence.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return fixture.demoCoalitionEvidence.map(CoalitionEvidence.fromJson).toList();
    }
  }

  /// In demo mode, approximates a coalition simulation client-side from
  /// the bundled forecast's per-list seat medians/ranges (the real
  /// endpoint runs this server-side from actual simulation draws — see
  /// services/api/app/api/v1/coalitions.py).
  Future<CoalitionSimulationResult> simulate({
    required String forecastRunId,
    required List<String> electoralListIds,
  }) async {
    if (demoMode) {
      final results = (fixture.demoForecastRun['party_results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((r) => electoralListIds.contains(r['electoral_list_id']));
      final median = results.fold<int>(0, (sum, r) => sum + (r['seats_median'] as int));
      final low80 = results.fold<int>(0, (sum, r) => sum + (r['seats_low80'] as int));
      final high80 = results.fold<int>(0, (sum, r) => sum + (r['seats_high80'] as int));
      const threshold = 67;
      final prob = median >= threshold
          ? 1.0
          : (high80 > low80 ? ((high80 - threshold) / (high80 - low80)).clamp(0.0, 1.0) : 0.0);
      return CoalitionSimulationResult(
        electoralListIds: electoralListIds,
        majorityThreshold: threshold,
        seatsMedian: median,
        seatsLow80: low80,
        seatsHigh80: high80,
        majorityProbability: double.parse(prob.toStringAsFixed(4)),
      );
    }
    final res = await _client.dio.post('/coalitions/simulate', data: {
      'forecast_run_id': forecastRunId,
      'electoral_list_ids': electoralListIds,
    });
    return CoalitionSimulationResult.fromJson(res.data as Map<String, dynamic>);
  }
}
