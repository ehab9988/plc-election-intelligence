/// Forecast DTOs. Terminology matches services/api/app/schemas/forecast.py
/// and spec section 81 exactly — never rename these fields casually,
/// screens depend on the distinction between polling average / forecast
/// vote share / seats.
class ForecastPartyResult {
  final String electoralListId;
  final String listNameAr;
  final String listNameEn;
  final String? colorHex;

  final double pollingAveragePct;
  final double forecastVoteShareMedian;
  final double voteShareLow80;
  final double voteShareHigh80;
  final double voteShareLow95;
  final double voteShareHigh95;

  final int seatsMedian;
  final double seatsMean;
  final int seatsLow50;
  final int seatsHigh50;
  final int seatsLow80;
  final int seatsHigh80;
  final int seatsLow95;
  final int seatsHigh95;

  final double probabilityLargestList;
  final double probabilityCrossThreshold;
  final double probabilityMajorityAlone;

  const ForecastPartyResult({
    required this.electoralListId,
    required this.listNameAr,
    required this.listNameEn,
    required this.pollingAveragePct,
    required this.forecastVoteShareMedian,
    required this.voteShareLow80,
    required this.voteShareHigh80,
    required this.voteShareLow95,
    required this.voteShareHigh95,
    required this.seatsMedian,
    required this.seatsMean,
    required this.seatsLow50,
    required this.seatsHigh50,
    required this.seatsLow80,
    required this.seatsHigh80,
    required this.seatsLow95,
    required this.seatsHigh95,
    required this.probabilityLargestList,
    required this.probabilityCrossThreshold,
    required this.probabilityMajorityAlone,
    this.colorHex,
  });

  factory ForecastPartyResult.fromJson(Map<String, dynamic> json) => ForecastPartyResult(
        electoralListId: json['electoral_list_id'] as String,
        listNameAr: json['list_name_ar'] as String,
        listNameEn: json['list_name_en'] as String,
        colorHex: json['color_hex'] as String?,
        pollingAveragePct: (json['polling_average_pct'] as num).toDouble(),
        forecastVoteShareMedian: (json['forecast_vote_share_median'] as num).toDouble(),
        voteShareLow80: (json['vote_share_low80'] as num).toDouble(),
        voteShareHigh80: (json['vote_share_high80'] as num).toDouble(),
        voteShareLow95: (json['vote_share_low95'] as num).toDouble(),
        voteShareHigh95: (json['vote_share_high95'] as num).toDouble(),
        seatsMedian: json['seats_median'] as int,
        seatsMean: (json['seats_mean'] as num).toDouble(),
        seatsLow50: json['seats_low50'] as int,
        seatsHigh50: json['seats_high50'] as int,
        seatsLow80: json['seats_low80'] as int,
        seatsHigh80: json['seats_high80'] as int,
        seatsLow95: json['seats_low95'] as int,
        seatsHigh95: json['seats_high95'] as int,
        probabilityLargestList: (json['probability_largest_list'] as num).toDouble(),
        probabilityCrossThreshold: (json['probability_cross_threshold'] as num).toDouble(),
        probabilityMajorityAlone: (json['probability_majority_alone'] as num).toDouble(),
      );
}

class ForecastRun {
  final String id;
  final String electionId;
  final String modelVersion;
  final String datasetVersion;
  final DateTime dataCutoffAt;
  final int simulationsPerformed;
  final int randomSeed;
  final String status;
  final String? assumptionsNotes;
  final String? changeSummary;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final int majorityThreshold;
  final List<ForecastPartyResult> partyResults;

  const ForecastRun({
    required this.id,
    required this.electionId,
    required this.modelVersion,
    required this.datasetVersion,
    required this.dataCutoffAt,
    required this.simulationsPerformed,
    required this.randomSeed,
    required this.status,
    required this.createdAt,
    required this.majorityThreshold,
    required this.partyResults,
    this.assumptionsNotes,
    this.changeSummary,
    this.publishedAt,
  });

  factory ForecastRun.fromJson(Map<String, dynamic> json) => ForecastRun(
        id: json['id'] as String,
        electionId: json['election_id'] as String,
        modelVersion: json['model_version'] as String,
        datasetVersion: json['dataset_version'] as String,
        dataCutoffAt: DateTime.parse(json['data_cutoff_at'] as String),
        simulationsPerformed: json['simulations_performed'] as int,
        randomSeed: json['random_seed'] as int,
        status: json['status'] as String,
        assumptionsNotes: json['assumptions_notes'] as String?,
        changeSummary: json['change_summary'] as String?,
        publishedAt: json['published_at'] == null ? null : DateTime.parse(json['published_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        majorityThreshold: json['majority_threshold'] as int,
        partyResults: (json['party_results'] as List<dynamic>? ?? [])
            .map((e) => ForecastPartyResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
