import 'package:shared_preferences/shared_preferences.dart';

/// Centralizes the product name and API base URL so a future rebrand or
/// pointing at a different deployment touches one place (spec: "Architecture
/// and branding must make it easy to rename later").
class AppConfig {
  static const String productName = 'PLC Election Intelligence';
  static const String defaultApiBaseUrl = 'http://localhost:8000/api/v1';

  static const _baseUrlPrefKey = 'api_base_url';
  static const _demoModePrefKey = 'demo_mode_enabled';

  final String apiBaseUrl;
  final bool demoMode;

  const AppConfig({required this.apiBaseUrl, required this.demoMode});

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      apiBaseUrl: prefs.getString(_baseUrlPrefKey) ?? defaultApiBaseUrl,
      // No backend is assumed reachable out of the box, so a fresh
      // install starts in demo mode with bundled fixture data rather
      // than showing a blank/error screen (section 67, 35).
      demoMode: prefs.getBool(_demoModePrefKey) ?? true,
    );
  }

  static Future<void> save({required String apiBaseUrl, required bool demoMode}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, apiBaseUrl);
    await prefs.setBool(_demoModePrefKey, demoMode);
  }
}
