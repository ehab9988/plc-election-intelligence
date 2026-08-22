import 'package:flutter_test/flutter_test.dart';
import 'package:plc_election_client/models/coalition.dart';
import 'package:plc_election_client/models/election.dart';
import 'package:plc_election_client/models/forecast.dart';
import 'package:plc_election_client/models/party.dart';
import 'package:plc_election_client/services/report_service.dart';

// useArabicFont: false throughout — keeps these hermetic/offline (no
// Google Fonts network fetch), per report_service.dart's documented test
// escape hatch. English-language report generation never needs network
// (see the class doc comment); this suite exercises that Latin path.

ForecastRun _sampleRun() => ForecastRun(
      id: 'run-1',
      electionId: 'election-1',
      modelVersion: 'test-1.0.0',
      datasetVersion: 'test-dataset',
      dataCutoffAt: DateTime.utc(2026, 8, 22),
      simulationsPerformed: 1000,
      randomSeed: 1,
      status: 'published',
      createdAt: DateTime.utc(2026, 8, 22),
      majorityThreshold: 67,
      partyResults: [
        ForecastPartyResult(
          electoralListId: 'list-a',
          listNameAr: 'أ',
          listNameEn: 'List A',
          pollingAveragePct: 40,
          forecastVoteShareMedian: 41,
          voteShareLow80: 37,
          voteShareHigh80: 45,
          voteShareLow95: 34,
          voteShareHigh95: 48,
          seatsMedian: 54,
          seatsMean: 53.5,
          seatsLow50: 51,
          seatsHigh50: 57,
          seatsLow80: 47,
          seatsHigh80: 61,
          seatsLow95: 42,
          seatsHigh95: 66,
          probabilityLargestList: 0.6,
          probabilityCrossThreshold: 1.0,
          probabilityMajorityAlone: 0.05,
        ),
      ],
    );

ElectionRuleSetSummary _sampleRules() => ElectionRuleSetSummary(
      id: 'rules-1',
      version: '1.0.0',
      effectiveFrom: DateTime.utc(2026, 1, 1),
      effectiveUntil: null,
      electoralSystem: 'closed-list PR',
      districtStructure: 'single national constituency',
      totalSeats: 132,
      thresholdFraction: 0.01,
      allocationMethod: 'sainte_lague',
      minimumCandidateAge: 23,
      allowsIndividualCandidateVotes: false,
      sourceDocument: 'test',
      verifiedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  test('buildForecastReport produces a non-empty valid PDF', () async {
    final bytes = await ReportService.buildForecastReport(
      run: _sampleRun(),
      rules: _sampleRules(),
      title: 'Forecast Report',
      generatedOnLabel: 'Generated',
      modelVersionLabel: 'Model version',
      seatsLabel: 'Seats',
      voteShareLabel: 'Vote share',
      disclaimer: 'Test disclaimer',
      useArabicFont: false,
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('buildPartyReport produces a non-empty valid PDF', () async {
    final party = Party(
      id: 'party-1',
      nameAr: 'حزب',
      nameEn: 'Test Party',
      registrationStatus: 'announced_intention',
      verificationConfidence: 'medium',
    );
    final bytes = await ReportService.buildPartyReport(
      party: party,
      title: 'Party Report',
      generatedOnLabel: 'Generated',
      disclaimer: 'Test disclaimer',
      useArabicFont: false,
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('buildCandidateReport produces a non-empty valid PDF', () async {
    final bytes = await ReportService.buildCandidateReport(
      fullNameAr: 'مرشح',
      fullNameEn: 'Test Candidate',
      listNameEn: 'List A',
      listRank: 5,
      seatProbability: 0.72,
      seatsMedian: 54,
      seatsLow80: 47,
      seatsHigh80: 61,
      title: 'Candidate Report',
      generatedOnLabel: 'Generated',
      disclaimer: 'Test disclaimer',
      useArabicFont: false,
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('buildCoalitionReport produces a non-empty valid PDF', () async {
    final result = CoalitionSimulationResult(
      electoralListIds: const ['list-a', 'list-b'],
      majorityThreshold: 67,
      seatsMedian: 70,
      seatsLow80: 60,
      seatsHigh80: 80,
      majorityProbability: 0.65,
    );
    final bytes = await ReportService.buildCoalitionReport(
      listNames: const ['List A', 'List B'],
      result: result,
      title: 'Coalition Report',
      generatedOnLabel: 'Generated',
      disclaimer: 'Test disclaimer',
      useArabicFont: false,
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
