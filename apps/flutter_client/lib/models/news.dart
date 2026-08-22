class NewsArticle {
  final String id;
  final String headline;
  final String? author;
  final DateTime publishedAt;
  final String canonicalUrl;
  final String? permittedSnippet;
  final String? imageUrl;
  final String language;
  final double? importanceScore;

  const NewsArticle({
    required this.id,
    required this.headline,
    required this.publishedAt,
    required this.canonicalUrl,
    required this.language,
    this.author,
    this.permittedSnippet,
    this.imageUrl,
    this.importanceScore,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        id: json['id'] as String,
        headline: json['headline'] as String,
        author: json['author'] as String?,
        publishedAt: DateTime.parse(json['published_at'] as String),
        canonicalUrl: json['canonical_url'] as String,
        permittedSnippet: json['permitted_snippet'] as String?,
        imageUrl: json['image_url'] as String?,
        language: json['language'] as String,
        importanceScore: (json['importance_score'] as num?)?.toDouble(),
      );
}

class PoliticalEvent {
  final String id;
  final DateTime eventTimestamp;
  final String category;
  final String titleAr;
  final String titleEn;
  final String magnitude;
  final String confidence;

  const PoliticalEvent({
    required this.id,
    required this.eventTimestamp,
    required this.category,
    required this.titleAr,
    required this.titleEn,
    required this.magnitude,
    required this.confidence,
  });

  factory PoliticalEvent.fromJson(Map<String, dynamic> json) => PoliticalEvent(
        id: json['id'] as String,
        eventTimestamp: DateTime.parse(json['event_timestamp'] as String),
        category: json['category'] as String,
        titleAr: json['title_ar'] as String,
        titleEn: json['title_en'] as String,
        magnitude: json['magnitude'] as String,
        confidence: json['confidence'] as String,
      );
}
