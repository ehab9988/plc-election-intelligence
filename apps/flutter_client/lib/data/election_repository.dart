import '../core/api_client.dart';
import '../models/election.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class ElectionRepository {
  final ApiClient _client;
  final bool demoMode;

  ElectionRepository(this._client, {required this.demoMode});

  Future<Election> getCurrentElection() async {
    if (demoMode) return Election.fromJson(fixture.demoElection);
    try {
      final res = await _client.dio.get('/elections/current');
      return Election.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return Election.fromJson(fixture.demoElection);
    }
  }

  Future<ElectionRuleSetSummary> getRules(String electionId) async {
    if (demoMode) return ElectionRuleSetSummary.fromJson(fixture.demoRuleSet);
    try {
      final res = await _client.dio.get('/elections/$electionId/rules');
      return ElectionRuleSetSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return ElectionRuleSetSummary.fromJson(fixture.demoRuleSet);
    }
  }

  Future<List<TimelineEvent>> getTimeline(String electionId) async {
    if (demoMode) return fixture.demoTimeline.map(TimelineEvent.fromJson).toList();
    try {
      final res = await _client.dio.get('/elections/$electionId/timeline');
      return (res.data as List<dynamic>).map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return fixture.demoTimeline.map(TimelineEvent.fromJson).toList();
    }
  }
}
