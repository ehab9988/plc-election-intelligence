import '../core/api_client.dart';
import '../models/news.dart';
import 'fixtures/demo_fixture.dart' as fixture;

class NewsRepository {
  final ApiClient _client;
  final bool demoMode;

  NewsRepository(this._client, {required this.demoMode});

  Future<List<NewsArticle>> listNews() async {
    if (demoMode) return fixture.demoNews.map(NewsArticle.fromJson).toList();
    try {
      final res = await _client.dio.get('/news');
      return (res.data as List<dynamic>).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return fixture.demoNews.map(NewsArticle.fromJson).toList();
    }
  }
}
