// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PLC Election Intelligence';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navForecast => 'Forecast';

  @override
  String get navParliament => 'Parliament';

  @override
  String get navPolls => 'Polls';

  @override
  String get navParties => 'Parties';

  @override
  String get navCoalitionLab => 'Coalition Lab';

  @override
  String get navNews => 'News';

  @override
  String get navMethodology => 'Methodology';

  @override
  String get navSettings => 'Settings';

  @override
  String get electionCountdown => 'Election Day';

  @override
  String forecastUpdated(String time) {
    return 'Forecast updated $time';
  }

  @override
  String dataCutoff(String time) {
    return 'Data cutoff: $time';
  }

  @override
  String get largestListProbability => 'Probability of being largest list';

  @override
  String get medianSeats => 'Median seats';

  @override
  String get range80 => '80% range';

  @override
  String get range95 => '95% range';

  @override
  String get voteShareMedian => 'Vote share (median)';

  @override
  String get probabilityMajority => 'Probability of majority alone';

  @override
  String get probabilityThreshold => 'Probability of crossing threshold';

  @override
  String get pollingAverage => 'Polling Average';

  @override
  String get nowcast => 'Nowcast';

  @override
  String get electionDayForecast => 'Election-Day Forecast';

  @override
  String majorityLine(int seats) {
    return 'Majority: $seats seats';
  }

  @override
  String get seatProbability => 'Estimated probability of winning a PLC seat';

  @override
  String listRank(int rank) {
    return 'List position: #$rank';
  }

  @override
  String get viewSource => 'View source';

  @override
  String get sources => 'Sources';

  @override
  String get registrationStatus => 'Registration status';

  @override
  String verifiedOn(String date) {
    return 'Verified $date';
  }

  @override
  String get undecided => 'Undecided';

  @override
  String get coalitionLabTitle => 'Coalition Lab';

  @override
  String get coalitionLabHint => 'Select lists to build a coalition scenario';

  @override
  String get combinedSeats => 'Combined seats';

  @override
  String get majorityProbability => 'Probability of reaching a majority';

  @override
  String get methodologyTitle => 'Methodology';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get forecastVsResults => 'FORECAST — not an official result';

  @override
  String get insufficientData => 'Insufficient data';

  @override
  String get demoDataBanner =>
      'Showing bundled demo data — connect to a live API in Settings for production use.';

  @override
  String elevatedUncertainty(String reason) {
    return 'Forecast uncertainty is elevated: $reason';
  }

  @override
  String get searchHint => 'Search parties, candidates, polls…';

  @override
  String get candidateBiography => 'Biography';

  @override
  String get candidateGovernorate => 'Governorate';

  @override
  String get candidateHometown => 'Hometown';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get noData => 'No data available yet';

  @override
  String get navMore => 'More';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageSystem => 'System default';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get generatingReport => 'Generating report…';

  @override
  String get reportGenerated => 'Report ready';

  @override
  String get projectedLargestList => 'Projected largest list';

  @override
  String get viewFullForecast => 'View full forecast';

  @override
  String get latestPolls => 'Latest Polls';

  @override
  String get latestForecastTitle => 'Latest Forecast';

  @override
  String get dataCutoffLabel => 'Data cutoff';

  @override
  String get electionDay => 'Election Day';

  @override
  String daysUntilElection(int days) {
    return '$days days until election day';
  }

  @override
  String get newsTitle => 'News';

  @override
  String get pollsTitle => 'Polls';

  @override
  String get partiesTitle => 'Parties';

  @override
  String get candidatesTitle => 'Candidates';

  @override
  String generatedOn(String date) {
    return 'Generated $date';
  }

  @override
  String get modelVersionLabel => 'Model version';

  @override
  String get seatsLabel => 'Seats';

  @override
  String get voteShareLabel => 'Vote share';

  @override
  String get sourceCitationsHeading => 'Source Citations';

  @override
  String get politicalCompatibilityEvidence =>
      'Political Compatibility Evidence';

  @override
  String get mathematicalFeasibilityNote =>
      'Mathematical feasibility only — political compatibility is shown separately and is never presented as a formation probability.';

  @override
  String get settingsDemoMode => 'Demo mode (bundled sample data)';

  @override
  String get settingsApiBaseUrl => 'API base URL';

  @override
  String get settingsSave => 'Save';

  @override
  String get reportPartyTitle => 'Party Report';

  @override
  String get reportCandidateTitle => 'Candidate Report';

  @override
  String get reportForecastTitle => 'Forecast Report';

  @override
  String get reportCoalitionTitle => 'Coalition Scenario Report';

  @override
  String get notAnOfficialResult =>
      'This is a statistical forecast, not an official result.';

  @override
  String get reportDisclaimer =>
      'Generated by PLC Election Intelligence. Every figure is a model estimate with an explicit data cutoff and uncertainty range — see the Methodology screen for the full statistical methodology.';
}
