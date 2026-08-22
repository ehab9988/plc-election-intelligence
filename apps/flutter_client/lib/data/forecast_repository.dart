import '../core/api_client.dart';
import '../models/forecast.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class ForecastRepository {
  final ApiClient _client;
  final bool demoMode;

  ForecastRepository(this._client, {required this.demoMode});

  Future<ForecastRun> getLatest(String electionId) async {
    if (demoMode) return ForecastRun.fromJson(fixture.demoForecastRun);
    try {
      final res = await _client.dio.get('/forecast/latest', queryParameters: {'election_id': electionId});
      return ForecastRun.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return ForecastRun.fromJson(fixture.demoForecastRun);
    }
  }

  Future<List<ForecastRun>> getHistory(String electionId) async {
    if (demoMode) return [ForecastRun.fromJson(fixture.demoForecastRun)];
    try {
      final res = await _client.dio.get('/forecast/history', queryParameters: {'election_id': electionId});
      return (res.data as List<dynamic>).map((e) => ForecastRun.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [ForecastRun.fromJson(fixture.demoForecastRun)];
    }
  }
}
