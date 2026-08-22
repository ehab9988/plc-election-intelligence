import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/static_data_client.dart';
import '../models/news.dart';
import 'remote_fetch.dart';

class NewsRepository with RemoteFetch {
  @override
  final ApiClient client;
  @override
  final StaticDataClient staticClient;
  @override
  final DataSource dataSource;

  NewsRepository(this.client, this.staticClient, {required this.dataSource});

  Future<List<NewsArticle>> listNews() async {
    final data = await fetch('/news', 'news');
    return (data as List<dynamic>).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
  }
}
