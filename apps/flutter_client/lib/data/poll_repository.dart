import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/poll.dart';
import 'remote_fetch.dart';

class PollRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  PollRepository(this.client, this.staticClient, {required this.dataSource});

  Future<List<Poll>> listPolls(String electionId) async {
    final data = await fetch('/polls', 'polls', query: {'election_id': electionId});
    return (data as List<dynamic>).map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PollingAveragePoint>> getPollingAverage(String electionId) async {
    final data = await fetch('/polling-average', 'polling-average', query: {'election_id': electionId});
    return (data as List<dynamic>).map((e) => PollingAveragePoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
