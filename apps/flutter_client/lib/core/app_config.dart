import 'package:shared_preferences/shared_preferences.dart';

/// Where the app's data comes from. `liveApi` calls a running FastAPI
/// backend (services/api); `staticGithub` fetches pre-generated JSON
/// snapshots committed to a GitHub repo by scripts/export_static_data.py
/// — a deployment path with no server running at all. See
/// docs/STATIC_GITHUB_DEPLOYMENT.md.
enum DataSource { liveApi, staticGithub }

/// Centralizes the product name and data-source config so a future
/// rebrand or pointing at a different deployment touches one place
/// (spec: "Architecture and branding must make it easy to rename later").
class AppConfig {
  static const String productName = 'PLC Election Intelligence';
  static const String defaultApiBaseUrl = 'http://localhost:8000/api/v1';
  static const String defaultStaticBaseUrl =
      'https://raw.githubusercontent.com/ehab9988/plc-election-intelligence/main/data';

  static const _baseUrlPrefKey = 'api_base_url';
  static const _staticBaseUrlPrefKey = 'static_base_url';
  static const _dataSourcePrefKey = 'data_source';

  final String apiBaseUrl;
  final String staticBaseUrl;
  final DataSource dataSource;

  const AppConfig({
    required this.apiBaseUrl,
    required this.staticBaseUrl,
    required this.dataSource,
  });

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      apiBaseUrl: prefs.getString(_baseUrlPrefKey) ?? defaultApiBaseUrl,
      staticBaseUrl: prefs.getString(_staticBaseUrlPrefKey) ?? defaultStaticBaseUrl,
      // No local server is assumed running out of the box, so a fresh
      // install defaults to the static GitHub-hosted snapshot rather
      // than a live API at localhost that likely isn't there.
      dataSource: DataSource.values.firstWhere(
        (v) => v.name == prefs.getString(_dataSourcePrefKey),
        orElse: () => DataSource.staticGithub,
      ),
    );
  }

  static Future<void> save({
    required String apiBaseUrl,
    required String staticBaseUrl,
    required DataSource dataSource,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, apiBaseUrl);
    await prefs.setString(_staticBaseUrlPrefKey, staticBaseUrl);
    await prefs.setString(_dataSourcePrefKey, dataSource.name);
  }
}
