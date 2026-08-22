import 'dart:convert';

import 'package:dio/dio.dart';

import 'app_config.dart';

/// Thin GET-only client for the static (GitHub-hosted) data source — a
/// deployment path with no live server: a GitHub Actions job runs
/// scripts/export_static_data.py and commits the JSON to the repo's
/// data/ directory, and this fetches those files directly (typically
/// from raw.githubusercontent.com). The path convention (query
/// parameters folded into the file path instead of a query string) is
/// defined by that script and must be kept in sync with the paths used
/// here — see docs/STATIC_GITHUB_DEPLOYMENT.md.
class StaticDataClient {
  final Dio dio;

  StaticDataClient(AppConfig config)
      : dio = Dio(BaseOptions(
          baseUrl: config.staticBaseUrl,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<dynamic> getJson(String path) async {
    // Dio's automatic JSON parsing keys off the response's Content-Type
    // header, but raw.githubusercontent.com serves .json files as
    // text/plain — so it never gets auto-decoded and res.data ends up
    // as a raw String. Force plain-text and decode ourselves instead of
    // relying on content-type sniffing.
    final res = await dio.get<String>('/$path.json', options: Options(responseType: ResponseType.plain));
    return jsonDecode(res.data!);
  }
}
