import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/forecast.dart';
import 'remote_fetch.dart';

class ForecastRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  ForecastRepository(this.client, this.staticClient, {required this.dataSource});

  Future<ForecastRun> getLatest(String electionId) async {
    final data = await fetch(
      '/forecast/latest',
      'forecast/latest/$electionId',
      query: {'election_id': electionId},
    );
    return ForecastRun.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ForecastRun>> getHistory(String electionId) async {
    final data = await fetch(
      '/forecast/history',
      'forecast/history/$electionId',
      query: {'election_id': electionId},
    );
    return (data as List<dynamic>).map((e) => ForecastRun.fromJson(e as Map<String, dynamic>)).toList();
  }
}
