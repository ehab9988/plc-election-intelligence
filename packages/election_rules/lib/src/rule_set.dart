/// Versioned electoral rule configuration.
///
/// Election law can change (amendments, court rulings, CEC clarifications),
/// so rules are never hard-coded into the allocation algorithms. Instead an
/// [ElectionRuleSet] is a data record, valid for a date range, that the
/// allocation engine consumes. Administrators create a new version rather
/// than mutating an existing one, so historical forecasts remain
/// reproducible against the rules that were actually in force at the time.
library;

/// Seat allocation method a rule set may specify.
///
/// Only [sainteLague] is implemented today because it is the method
/// confirmed for the 2026 PLC election. Other members exist so the engine
/// can be extended to other Palestinian elections (e.g. local councils)
/// without a breaking API change.
enum AllocationMethod { sainteLague, modifiedSainteLague, dHondt }

/// A single reserved/quota seat carve-out (e.g. Christian seats),
/// applying only once officially verified in the governing legal text.
///
/// [count] seats are set aside for [category] and are allocated according
/// to the legally documented mechanism, which is intentionally NOT
/// hard-coded here — [mechanismDescription] is a human-readable pointer to
/// the verified legal text an analyst supplied, and [mechanismCode] is an
/// opaque key the forecasting layer can switch on once the mechanism has
/// been implemented and tested. Until an admin marks
/// [verified] = true, the seat count is tracked but MUST NOT be
/// silently subtracted from the general proportional pool by any
/// automated process.
class ReservedSeatRule {
  final String category;
  final int count;
  final String mechanismDescription;
  final String? mechanismCode;
  final bool verified;
  final String sourceDocument;

  const ReservedSeatRule({
    required this.category,
    required this.count,
    required this.mechanismDescription,
    required this.sourceDocument,
    this.mechanismCode,
    this.verified = false,
  });
}

/// A candidate-list gender quota requirement (e.g. "at least 33% women").
class GenderQuota {
  final double minimumFraction;
  final String description;

  const GenderQuota({required this.minimumFraction, required this.description});
}

class ElectionRuleSet {
  /// Stable id for the rule set row (UUID in the database layer).
  final String id;

  /// Which election this rule set governs.
  final String electionId;

  /// Rule set version, e.g. "1.0.0". Bump on every legally meaningful change.
  final String version;

  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;

  /// Human-readable description of the electoral system, e.g.
  /// "Nationwide closed-list proportional representation".
  final String electoralSystem;

  /// e.g. "single national constituency" vs. multi-district. Kept as a
  /// free-text + structured discriminator so district-based systems (as
  /// used in some historical Palestinian elections) can be represented
  /// without redesigning the schema.
  final String districtStructure;

  final int totalSeats;

  /// Legal threshold a list must clear to enter allocation, expressed as a
  /// fraction of valid votes (e.g. 0.01 for 1%).
  final double thresholdFraction;

  final AllocationMethod allocationMethod;

  final List<ReservedSeatRule> reservedSeats;
  final GenderQuota? genderQuota;

  final int minimumCandidateAge;
  final int? listMinimumCandidates;
  final int? listMaximumCandidates;

  /// Whether candidates are voted for individually under this rule set.
  /// False for the 2026 closed-list PLC system: this flag is what stops
  /// the rest of the codebase from ever computing a candidate-level vote
  /// share (see CRITICAL ACCURACY RULE #7).
  final bool allowsIndividualCandidateVotes;

  final String sourceDocument;
  final DateTime verifiedAt;

  const ElectionRuleSet({
    required this.id,
    required this.electionId,
    required this.version,
    required this.effectiveFrom,
    required this.electoralSystem,
    required this.districtStructure,
    required this.totalSeats,
    required this.thresholdFraction,
    required this.allocationMethod,
    required this.minimumCandidateAge,
    required this.sourceDocument,
    required this.verifiedAt,
    this.effectiveUntil,
    this.reservedSeats = const [],
    this.genderQuota,
    this.listMinimumCandidates,
    this.listMaximumCandidates,
    this.allowsIndividualCandidateVotes = false,
  });

  /// Majority threshold derived from [totalSeats], never a hard-coded
  /// constant: floor(totalSeats / 2) + 1. For 132 seats this is 67.
  int get majorityThreshold => (totalSeats ~/ 2) + 1;

  /// Seats actually available to the general proportional allocation, i.e.
  /// [totalSeats] minus reserved seats that have been legally verified.
  /// Unverified reserved-seat rules do not reduce the pool, by design.
  int get generalPoolSeats =>
      totalSeats - reservedSeats.where((r) => r.verified).fold(0, (a, r) => a + r.count);

  bool isActiveOn(DateTime date) =>
      !date.isBefore(effectiveFrom) && (effectiveUntil == null || date.isBefore(effectiveUntil!));

  /// The verified baseline for the 2026 Palestinian Legislative Council
  /// election as of August 2026. Reserved seats and the gender quota are
  /// modeled but marked unverified pending the complete legal mechanism
  /// text, per the "never assume implementation details" instruction.
  factory ElectionRuleSet.plc2026Baseline({required String electionId}) => ElectionRuleSet(
        id: 'ruleset-plc-2026-v1',
        electionId: electionId,
        version: '1.0.0',
        effectiveFrom: DateTime.utc(2026, 1, 1),
        electoralSystem: 'Nationwide closed-list proportional representation',
        districtStructure: 'Single national constituency',
        totalSeats: 132,
        thresholdFraction: 0.01,
        allocationMethod: AllocationMethod.sainteLague,
        minimumCandidateAge: 23,
        genderQuota: const GenderQuota(
          minimumFraction: 0.33,
          description: 'At least 33% women representation on candidate lists '
              'under the current amendment to the election law.',
        ),
        reservedSeats: const [
          ReservedSeatRule(
            category: 'Christian',
            count: 7,
            mechanismDescription:
                'At least seven PLC seats allocated to Christian citizens under '
                'the relevant decree. Exact allocation mechanism (best-loser '
                'top-up vs. dedicated sub-list vs. other) requires confirmation '
                'against the complete legal text before being applied '
                'automatically.',
            sourceDocument: 'Palestinian election law amendment (decree) — '
                'pending full-text legal citation',
            verified: false,
          ),
        ],
        allowsIndividualCandidateVotes: false,
        sourceDocument:
            'Palestinian Central Elections Commission / Palestinian election law — '
            'baseline captured August 2026; supersede via a new versioned '
            'ElectionRuleSet whenever the CEC publishes an update.',
        verifiedAt: DateTime.utc(2026, 8, 1),
      );
}
