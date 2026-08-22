import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/coalition.dart';
import 'remote_fetch.dart';

class CoalitionRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  CoalitionRepository(this.client, this.staticClient, {required this.dataSource});

  Future<List<CoalitionEvidence>> listEvidence({String? partyId}) async {
    final data = await fetch(
      '/coalitions',
      partyId == null ? 'coalitions/all' : 'coalitions/by-party/$partyId',
      query: {'party_id': ?partyId},
    );
    return (data as List<dynamic>).map((e) => CoalitionEvidence.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// AI-generated estimates only — never a calibrated statistic, see
  /// CoalitionFormationEstimate's doc comment.
  Future<List<CoalitionFormationEstimate>> listFormationEstimates({String? partyId}) async {
    final data = await fetch(
      '/coalitions/formation-estimates',
      'coalitions/formation-estimates',
      query: {'party_id': ?partyId},
    );
    final all = (data as List<dynamic>)
        .map((e) => CoalitionFormationEstimate.fromJson(e as Map<String, dynamic>))
        .toList();
    if (partyId == null || dataSource != DataSource.staticGithub) return all;
    // The static snapshot is one flat file (no per-party split like
    // coalitions/by-party/ has) — filter client-side instead.
    return all.where((e) => e.partyAId == partyId || e.partyBId == partyId).toList();
  }

  /// The static snapshot has no server to run this on, so it approximates
  /// the same math the live endpoint runs
  /// (services/api/app/api/v1/coalitions.py) from the already-published
  /// per-list seat medians/ranges in the latest static forecast. This
  /// loses cross-list correlation just like the server's own approximation
  /// does (see that file's docstring) — it is not a separate, lesser
  /// estimate, it is the same estimate computed client-side.
  Future<CoalitionSimulationResult> simulate({
    required String forecastRunId,
    required List<String> electoralListIds,
  }) async {
    if (dataSource == DataSource.staticGithub) {
      final election = await staticClient.getJson('elections/current') as Map<String, dynamic>;
      final forecast = await staticClient.getJson('forecast/latest/${election['id']}') as Map<String, dynamic>;
      final partyResults = (forecast['party_results'] as List<dynamic>).cast<Map<String, dynamic>>();
      final threshold = forecast['majority_threshold'] as int;
      final results = partyResults.where((r) => electoralListIds.contains(r['electoral_list_id']));
      final median = results.fold<int>(0, (sum, r) => sum + (r['seats_median'] as int));
      final low80 = results.fold<int>(0, (sum, r) => sum + (r['seats_low80'] as int));
      final high80 = results.fold<int>(0, (sum, r) => sum + (r['seats_high80'] as int));
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
    final res = await client.dio.post('/coalitions/simulate', data: {
      'forecast_run_id': forecastRunId,
      'electoral_list_ids': electoralListIds,
    });
    return CoalitionSimulationResult.fromJson(res.data as Map<String, dynamic>);
  }
}
