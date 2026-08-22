import '../core/api_client.dart';
import '../models/poll.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class PollRepository {
  final ApiClient _client;
  final bool demoMode;

  PollRepository(this._client, {required this.demoMode});

  Future<List<Poll>> listPolls(String electionId) async {
    if (demoMode) return [Poll.fromJson(fixture.demoPoll)];
    try {
      final res = await _client.dio.get('/polls', queryParameters: {'election_id': electionId});
      return (res.data as List<dynamic>).map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [Poll.fromJson(fixture.demoPoll)];
    }
  }

  Future<List<PollingAveragePoint>> getPollingAverage(String electionId) async {
    if (demoMode) return fixture.demoPollingAverage.map(PollingAveragePoint.fromJson).toList();
    try {
      final res = await _client.dio.get('/polling-average', queryParameters: {'election_id': electionId});
      return (res.data as List<dynamic>)
          .map((e) => PollingAveragePoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return fixture.demoPollingAverage.map(PollingAveragePoint.fromJson).toList();
    }
  }
}
