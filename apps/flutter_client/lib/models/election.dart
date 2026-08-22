/// Election + versioned rule-set DTOs mirroring services/api/app/schemas/election.py.
/// See docs/ELECTORAL_RULES.md for why the rule set is versioned rather
/// than hard-coded.
class Election {
  final String id;
  final String nameAr;
  final String nameEn;
  final String electionType;
  final DateTime? scheduledDate;
  final bool isCurrent;
  final String status;

  const Election({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.electionType,
    required this.scheduledDate,
    required this.isCurrent,
    required this.status,
  });

  factory Election.fromJson(Map<String, dynamic> json) => Election(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String,
        electionType: json['election_type'] as String,
        scheduledDate: json['scheduled_date'] == null ? null : DateTime.parse(json['scheduled_date'] as String),
        isCurrent: json['is_current'] as bool,
        status: json['status'] as String,
      );
}

class ElectionRuleSetSummary {
  final String id;
  final String version;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final String electoralSystem;
  final String districtStructure;
  final int totalSeats;
  final double thresholdFraction;
  final String allocationMethod;
  final int minimumCandidateAge;
  final bool allowsIndividualCandidateVotes;
  final String sourceDocument;
  final DateTime verifiedAt;

  const ElectionRuleSetSummary({
    required this.id,
    required this.version,
    required this.effectiveFrom,
    required this.effectiveUntil,
    required this.electoralSystem,
    required this.districtStructure,
    required this.totalSeats,
    required this.thresholdFraction,
    required this.allocationMethod,
    required this.minimumCandidateAge,
    required this.allowsIndividualCandidateVotes,
    required this.sourceDocument,
    required this.verifiedAt,
  });

  /// floor(totalSeats/2) + 1 — never a hard-coded literal in UI code.
  int get majorityThreshold => (totalSeats ~/ 2) + 1;

  factory ElectionRuleSetSummary.fromJson(Map<String, dynamic> json) => ElectionRuleSetSummary(
        id: json['id'] as String,
        version: json['version'] as String,
        effectiveFrom: DateTime.parse(json['effective_from'] as String),
        effectiveUntil: json['effective_until'] == null ? null : DateTime.parse(json['effective_until'] as String),
        electoralSystem: json['electoral_system'] as String,
        districtStructure: json['district_structure'] as String,
        totalSeats: json['total_seats'] as int,
        thresholdFraction: (json['threshold_fraction'] as num).toDouble(),
        allocationMethod: json['allocation_method'] as String,
        minimumCandidateAge: json['minimum_candidate_age'] as int,
        allowsIndividualCandidateVotes: json['allows_individual_candidate_votes'] as bool,
        sourceDocument: json['source_document'] as String,
        verifiedAt: DateTime.parse(json['verified_at'] as String),
      );
}

class TimelineEvent {
  final String id;
  final String milestone;
  final String labelAr;
  final String labelEn;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const TimelineEvent({
    required this.id,
    required this.milestone,
    required this.labelAr,
    required this.labelEn,
    required this.startsAt,
    required this.endsAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        milestone: json['milestone'] as String,
        labelAr: json['label_ar'] as String,
        labelEn: json['label_en'] as String,
        startsAt: json['starts_at'] == null ? null : DateTime.parse(json['starts_at'] as String),
        endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String),
      );
}
