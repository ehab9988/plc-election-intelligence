import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';

/// Shared fetch helper for repositories with a live-API path (query-param
/// FastAPI routes) and a static-GitHub path (pre-baked JSON files, with
/// whatever the query parameter would have selected folded into the file
/// path instead — see scripts/export_static_data.py and
/// docs/STATIC_GITHUB_DEPLOYMENT.md for the path convention). Demo mode
/// is handled separately by each repository since it reads from the
/// bundled fixture, not over HTTP.
mixin RemoteFetch {
  ApiClient get client;
  StaticDataClient get staticClient;
  DataSource get dataSource;

  Future<dynamic> fetch(String livePath, String staticPath, {Map<String, dynamic>? query}) {
    if (dataSource == DataSource.staticGithub) return staticClient.getJson(staticPath);
    return client.dio.get(livePath, queryParameters: query).then((res) => res.data);
  }
}
