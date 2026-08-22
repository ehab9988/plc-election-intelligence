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
  String get settingsApiBaseUrl => 'API base URL';

  @override
  String get settingsDataSource => 'Data source';

  @override
  String get settingsDataSourceLiveApi => 'Live API';

  @override
  String get settingsDataSourceStatic => 'Static (GitHub)';

  @override
  String get settingsStaticBaseUrl => 'Static data base URL';

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

  @override
  String get candidateDetailUnavailable =>
      'Candidate detail requires a live or static data connection. Configure a data source in Settings.';

  @override
  String get methodologyPollingAvgBody =>
      'A weighted average of polls that ask the same \"if elections were held today\" question. Weight = recency × sample size × population type × pollster quality. We never average polls that asked differently-worded questions, and we never count the same poll twice.';

  @override
  String get methodologyForecastBody =>
      'A Monte Carlo simulation built on the polling average, adding modeled uncertainty from house effects, turnout, and undecided voters. It reports a median and 50/80/95% ranges — never a single number presented as fact.';

  @override
  String get methodologySeatAllocationTitle => 'Seat Allocation';

  @override
  String get methodologySeatAllocationBody =>
      'Seats are allocated using the Sainte-Laguë method against the current, officially verified election rules (132 seats, 1% national threshold). The majority line is always computed as floor(total seats / 2) + 1 — for 132 seats, that is 67.';

  @override
  String get methodologyCandidateProbTitle => 'Candidate Seat Probability';

  @override
  String get methodologyCandidateProbBody =>
      'Because this is a closed-list election, voters vote for a list, not an individual candidate. A candidate\'s probability of winning a seat is the probability that their list wins at least as many seats as their position on the list, from the same simulations used for the seat forecast. We never calculate or display an individual candidate vote share.';

  @override
  String get methodologyCoalitionLabBody =>
      'Mathematical feasibility (the probability a set of lists reaches a majority) is computed directly from simulation data. Political compatibility — whether parties are willing to cooperate — is a separate, evidence-sourced assessment and is never presented as a calibrated probability unless the underlying methodology supports one.';

  @override
  String get methodologyUncertaintyTitle => 'Uncertainty & Model Health';

  @override
  String get methodologyUncertaintyBody =>
      'If the most recent high-quality poll is old, the forecast\'s uncertainty widens rather than staying artificially narrow. Every forecast carries a model version, dataset version, and data cutoff timestamp so it can be reproduced and audited.';

  @override
  String get methodologyFooter =>
      'This product applies the same methodology to every party or list. It does not recommend how to vote and does not adjust results to favor any political outcome.';

  @override
  String get pollingAverageExplanation =>
      'Weighted average of polls asking the same \"if elections were held today\" question. Not a forecast — see Methodology for the weighting formula.';

  @override
  String modelSimulationsLabel(String version, int count) {
    return 'Model $version · $count simulations';
  }

  @override
  String whyThisChangedLabel(String reason) {
    return 'Why this changed: $reason';
  }

  @override
  String medianSeatForecastLine(int majority, int total) {
    return 'Median-seat forecast. Majority line: $majority of $total seats.';
  }

  @override
  String fieldworkLabel(String start, String end) {
    return 'Fieldwork $start–$end';
  }

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get candidateListPendingForecast =>
      'Candidate list and per-candidate seat probabilities are available once this party\'s electoral list is linked to a published forecast run.';

  @override
  String get settingsAlerts => 'Alerts';

  @override
  String get settingsAlertsSubtitle =>
      'Follow parties, candidates, pollsters, governorates';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsSubscriptionSubtitle =>
      'Free · Premium · Professional (API access)';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get updatedLabel => 'Updated';

  @override
  String get justNowLabel => 'just now';

  @override
  String minutesAgoLabel(int minutes) {
    return '$minutes min ago';
  }

  @override
  String hoursAgoLabel(int hours) {
    return '$hours h ago';
  }

  @override
  String get forecastBadgeText => 'FORECAST';

  @override
  String seatsEightyRangeLabel(int low, int high) {
    return 'seats · 80% range $low–$high';
  }

  @override
  String get largestListProbShort => 'Largest-list prob.';

  @override
  String get majorityProbShort => 'Majority prob.';

  @override
  String get registrationStatusRumored => 'Rumored';

  @override
  String get registrationStatusConsidering => 'Considering';

  @override
  String get registrationStatusAnnouncedIntention => 'Announced Intention';

  @override
  String get registrationStatusSubmittedRegistration =>
      'Registration Submitted';

  @override
  String get registrationStatusProvisional => 'Provisional';

  @override
  String get registrationStatusOfficiallyApproved => 'Officially Approved';

  @override
  String get registrationStatusRejected => 'Rejected';

  @override
  String get registrationStatusWithdrawn => 'Withdrawn';

  @override
  String get registrationStatusDisqualified => 'Disqualified';

  @override
  String get confidenceLabel => 'Confidence';

  @override
  String get jointListReportedLabel => 'Joint list reported';

  @override
  String get jointListReportedTooltip =>
      'At least one source reports these parties running on one shared electoral list — not a probability, see the evidence below.';

  @override
  String get aiFormationEstimatesTitle => 'AI Coalition Estimates';

  @override
  String get aiEstimateDisclaimer =>
      'A language model\'s own estimate from web search — not a calibrated statistic like the mathematical feasibility above. Treat as a rough guide, not a fact.';

  @override
  String get aiEstimateLabel => 'AI estimate';
}
