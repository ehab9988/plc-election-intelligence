class PollResultEntry {
  final String label;
  final String? electoralListId;
  final double rawResponsePct;
  final double? normalizedPct;

  const PollResultEntry({
    required this.label,
    required this.rawResponsePct,
    this.electoralListId,
    this.normalizedPct,
  });

  factory PollResultEntry.fromJson(Map<String, dynamic> json) => PollResultEntry(
        label: json['label'] as String,
        electoralListId: json['electoral_list_id'] as String?,
        rawResponsePct: (json['raw_response_pct'] as num).toDouble(),
        normalizedPct: (json['normalized_pct'] as num?)?.toDouble(),
      );
}

class PollQuestion {
  final String id;
  final String questionTextAr;
  final String? questionTextEn;
  final String questionType;
  final List<PollResultEntry> results;

  const PollQuestion({
    required this.id,
    required this.questionTextAr,
    required this.questionType,
    required this.results,
    this.questionTextEn,
  });

  factory PollQuestion.fromJson(Map<String, dynamic> json) => PollQuestion(
        id: json['id'] as String,
        questionTextAr: json['question_text_ar'] as String,
        questionTextEn: json['question_text_en'] as String?,
        questionType: json['question_type'] as String,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => PollResultEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Poll {
  final String id;
  final String pollsterId;
  final String? sponsor;
  final DateTime publicationDate;
  final DateTime fieldworkStart;
  final DateTime fieldworkEnd;
  final int sampleSize;
  final double? marginOfError;
  final String mode;
  final String geographicPopulation;
  final int? westBankSampleSize;
  final int? gazaSampleSize;
  final String population;
  final bool manuallyVerified;
  final List<PollQuestion> questions;

  const Poll({
    required this.id,
    required this.pollsterId,
    required this.publicationDate,
    required this.fieldworkStart,
    required this.fieldworkEnd,
    required this.sampleSize,
    required this.mode,
    required this.geographicPopulation,
    required this.population,
    required this.manuallyVerified,
    required this.questions,
    this.sponsor,
    this.marginOfError,
    this.westBankSampleSize,
    this.gazaSampleSize,
  });

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        pollsterId: json['pollster_id'] as String,
        sponsor: json['sponsor'] as String?,
        publicationDate: DateTime.parse(json['publication_date'] as String),
        fieldworkStart: DateTime.parse(json['fieldwork_start'] as String),
        fieldworkEnd: DateTime.parse(json['fieldwork_end'] as String),
        sampleSize: json['sample_size'] as int,
        marginOfError: (json['margin_of_error'] as num?)?.toDouble(),
        mode: json['mode'] as String,
        geographicPopulation: json['geographic_population'] as String,
        westBankSampleSize: json['west_bank_sample_size'] as int?,
        gazaSampleSize: json['gaza_sample_size'] as int?,
        population: json['population'] as String,
        manuallyVerified: json['manually_verified'] as bool,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => PollQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PollingAveragePoint {
  final String electoralListId;
  final String listNameEn;
  final String listNameAr;
  final double weightedAveragePct;
  final double trendLow;
  final double trendHigh;
  final int nPollsUsed;
  final DateTime? mostRecentFieldworkEnd;

  const PollingAveragePoint({
    required this.electoralListId,
    required this.listNameEn,
    required this.listNameAr,
    required this.weightedAveragePct,
    required this.trendLow,
    required this.trendHigh,
    required this.nPollsUsed,
    this.mostRecentFieldworkEnd,
  });

  factory PollingAveragePoint.fromJson(Map<String, dynamic> json) => PollingAveragePoint(
        electoralListId: json['electoral_list_id'] as String,
        listNameEn: json['list_name_en'] as String,
        listNameAr: json['list_name_ar'] as String? ?? json['list_name_en'] as String,
        weightedAveragePct: (json['weighted_average_pct'] as num).toDouble(),
        trendLow: (json['trend_low'] as num).toDouble(),
        trendHigh: (json['trend_high'] as num).toDouble(),
        nPollsUsed: json['n_polls_used'] as int,
        mostRecentFieldworkEnd: json['most_recent_fieldwork_end'] == null
            ? null
            : DateTime.parse(json['most_recent_fieldwork_end'] as String),
      );
}
