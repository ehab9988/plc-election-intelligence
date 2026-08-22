class CoalitionEvidence {
  final String id;
  final String partyAId;
  final String partyBId;
  final String evidenceType; // supporting | conflicting
  // Distinct from evidenceType: reports the two parties running (or
  // announcing they will run) on ONE shared electoral list, not just a
  // broader political alliance. Still a sourced, confidence-tagged
  // signal — never a fabricated formation probability. See
  // docs/COALITION_MODEL.md.
  final bool impliesJointList;
  final String statementSummary;
  final String sourceId;
  final String confidence;

  const CoalitionEvidence({
    required this.id,
    required this.partyAId,
    required this.partyBId,
    required this.evidenceType,
    required this.impliesJointList,
    required this.statementSummary,
    required this.sourceId,
    required this.confidence,
  });

  factory CoalitionEvidence.fromJson(Map<String, dynamic> json) => CoalitionEvidence(
        id: json['id'] as String,
        partyAId: json['party_a_id'] as String,
        partyBId: json['party_b_id'] as String,
        evidenceType: json['evidence_type'] as String,
        impliesJointList: json['implies_joint_list'] as bool? ?? false,
        statementSummary: json['statement_summary'] as String,
        sourceId: json['source_id'] as String,
        confidence: json['confidence'] as String,
      );
}

class CoalitionSimulationResult {
  final List<String> electoralListIds;
  final int majorityThreshold;
  final int seatsMedian;
  final int seatsLow80;
  final int seatsHigh80;
  final double majorityProbability;

  const CoalitionSimulationResult({
    required this.electoralListIds,
    required this.majorityThreshold,
    required this.seatsMedian,
    required this.seatsLow80,
    required this.seatsHigh80,
    required this.majorityProbability,
  });

  factory CoalitionSimulationResult.fromJson(Map<String, dynamic> json) => CoalitionSimulationResult(
        electoralListIds: (json['electoral_list_ids'] as List<dynamic>).cast<String>(),
        majorityThreshold: json['majority_threshold'] as int,
        seatsMedian: json['seats_median'] as int,
        seatsLow80: json['seats_low80'] as int,
        seatsHigh80: json['seats_high80'] as int,
        majorityProbability: (json['majority_probability'] as num).toDouble(),
      );
}
