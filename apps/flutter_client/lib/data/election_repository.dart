import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/election.dart';
import 'remote_fetch.dart';

class ElectionRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  ElectionRepository(this.client, this.staticClient, {required this.dataSource});

  Future<Election> getCurrentElection() async {
    final data = await fetch('/elections/current', 'elections/current');
    return Election.fromJson(data as Map<String, dynamic>);
  }

  Future<ElectionRuleSetSummary> getRules(String electionId) async {
    final data = await fetch('/elections/$electionId/rules', 'elections/$electionId/rules');
    return ElectionRuleSetSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TimelineEvent>> getTimeline(String electionId) async {
    final data = await fetch('/elections/$electionId/timeline', 'elections/$electionId/timeline');
    return (data as List<dynamic>).map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
