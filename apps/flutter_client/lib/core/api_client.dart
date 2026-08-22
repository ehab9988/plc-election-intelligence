import 'package:dio/dio.dart';

import 'app_config.dart';

class ApiClient {
  final Dio dio;

  ApiClient(AppConfig config)
      : dio = Dio(BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 10),
        ));
}
