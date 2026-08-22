import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PLC Election Intelligence'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get navForecast;

  /// No description provided for @navParliament.
  ///
  /// In en, this message translates to:
  /// **'Parliament'**
  String get navParliament;

  /// No description provided for @navPolls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get navPolls;

  /// No description provided for @navParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get navParties;

  /// No description provided for @navCoalitionLab.
  ///
  /// In en, this message translates to:
  /// **'Coalition Lab'**
  String get navCoalitionLab;

  /// No description provided for @navNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get navNews;

  /// No description provided for @navMethodology.
  ///
  /// In en, this message translates to:
  /// **'Methodology'**
  String get navMethodology;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @electionCountdown.
  ///
  /// In en, this message translates to:
  /// **'Election Day'**
  String get electionCountdown;

  /// No description provided for @forecastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Forecast updated {time}'**
  String forecastUpdated(String time);

  /// No description provided for @dataCutoff.
  ///
  /// In en, this message translates to:
  /// **'Data cutoff: {time}'**
  String dataCutoff(String time);

  /// No description provided for @largestListProbability.
  ///
  /// In en, this message translates to:
  /// **'Probability of being largest list'**
  String get largestListProbability;

  /// No description provided for @medianSeats.
  ///
  /// In en, this message translates to:
  /// **'Median seats'**
  String get medianSeats;

  /// No description provided for @range80.
  ///
  /// In en, this message translates to:
  /// **'80% range'**
  String get range80;

  /// No description provided for @range95.
  ///
  /// In en, this message translates to:
  /// **'95% range'**
  String get range95;

  /// No description provided for @voteShareMedian.
  ///
  /// In en, this message translates to:
  /// **'Vote share (median)'**
  String get voteShareMedian;

  /// No description provided for @probabilityMajority.
  ///
  /// In en, this message translates to:
  /// **'Probability of majority alone'**
  String get probabilityMajority;

  /// No description provided for @probabilityThreshold.
  ///
  /// In en, this message translates to:
  /// **'Probability of crossing threshold'**
  String get probabilityThreshold;

  /// No description provided for @pollingAverage.
  ///
  /// In en, this message translates to:
  /// **'Polling Average'**
  String get pollingAverage;

  /// No description provided for @nowcast.
  ///
  /// In en, this message translates to:
  /// **'Nowcast'**
  String get nowcast;

  /// No description provided for @electionDayForecast.
  ///
  /// In en, this message translates to:
  /// **'Election-Day Forecast'**
  String get electionDayForecast;

  /// No description provided for @majorityLine.
  ///
  /// In en, this message translates to:
  /// **'Majority: {seats} seats'**
  String majorityLine(int seats);

  /// No description provided for @seatProbability.
  ///
  /// In en, this message translates to:
  /// **'Estimated probability of winning a PLC seat'**
  String get seatProbability;

  /// No description provided for @listRank.
  ///
  /// In en, this message translates to:
  /// **'List position: #{rank}'**
  String listRank(int rank);

  /// No description provided for @viewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get viewSource;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @registrationStatus.
  ///
  /// In en, this message translates to:
  /// **'Registration status'**
  String get registrationStatus;

  /// No description provided for @verifiedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String verifiedOn(String date);

  /// No description provided for @undecided.
  ///
  /// In en, this message translates to:
  /// **'Undecided'**
  String get undecided;

  /// No description provided for @coalitionLabTitle.
  ///
  /// In en, this message translates to:
  /// **'Coalition Lab'**
  String get coalitionLabTitle;

  /// No description provided for @coalitionLabHint.
  ///
  /// In en, this message translates to:
  /// **'Select lists to build a coalition scenario'**
  String get coalitionLabHint;

  /// No description provided for @combinedSeats.
  ///
  /// In en, this message translates to:
  /// **'Combined seats'**
  String get combinedSeats;

  /// No description provided for @majorityProbability.
  ///
  /// In en, this message translates to:
  /// **'Probability of reaching a majority'**
  String get majorityProbability;

  /// No description provided for @methodologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Methodology'**
  String get methodologyTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @forecastVsResults.
  ///
  /// In en, this message translates to:
  /// **'FORECAST — not an official result'**
  String get forecastVsResults;

  /// No description provided for @insufficientData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get insufficientData;

  /// No description provided for @elevatedUncertainty.
  ///
  /// In en, this message translates to:
  /// **'Forecast uncertainty is elevated: {reason}'**
  String elevatedUncertainty(String reason);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search parties, candidates, polls…'**
  String get searchHint;

  /// No description provided for @candidateBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get candidateBiography;

  /// No description provided for @candidateGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get candidateGovernorate;

  /// No description provided for @candidateHometown.
  ///
  /// In en, this message translates to:
  /// **'Hometown'**
  String get candidateHometown;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available yet'**
  String get noData;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @generatingReport.
  ///
  /// In en, this message translates to:
  /// **'Generating report…'**
  String get generatingReport;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report ready'**
  String get reportGenerated;

  /// No description provided for @projectedLargestList.
  ///
  /// In en, this message translates to:
  /// **'Projected largest list'**
  String get projectedLargestList;

  /// No description provided for @viewFullForecast.
  ///
  /// In en, this message translates to:
  /// **'View full forecast'**
  String get viewFullForecast;

  /// No description provided for @latestPolls.
  ///
  /// In en, this message translates to:
  /// **'Latest Polls'**
  String get latestPolls;

  /// No description provided for @latestForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Forecast'**
  String get latestForecastTitle;

  /// No description provided for @dataCutoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Data cutoff'**
  String get dataCutoffLabel;

  /// No description provided for @electionDay.
  ///
  /// In en, this message translates to:
  /// **'Election Day'**
  String get electionDay;

  /// No description provided for @daysUntilElection.
  ///
  /// In en, this message translates to:
  /// **'{days} days until election day'**
  String daysUntilElection(int days);

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @pollsTitle.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTitle;

  /// No description provided for @partiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get partiesTitle;

  /// No description provided for @candidatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidatesTitle;

  /// No description provided for @generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String generatedOn(String date);

  /// No description provided for @modelVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Model version'**
  String get modelVersionLabel;

  /// No description provided for @seatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seatsLabel;

  /// No description provided for @voteShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Vote share'**
  String get voteShareLabel;

  /// No description provided for @sourceCitationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Source Citations'**
  String get sourceCitationsHeading;

  /// No description provided for @politicalCompatibilityEvidence.
  ///
  /// In en, this message translates to:
  /// **'Political Compatibility Evidence'**
  String get politicalCompatibilityEvidence;

  /// No description provided for @mathematicalFeasibilityNote.
  ///
  /// In en, this message translates to:
  /// **'Mathematical feasibility only — political compatibility is shown separately and is never presented as a formation probability.'**
  String get mathematicalFeasibilityNote;

  /// No description provided for @settingsApiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get settingsApiBaseUrl;

  /// No description provided for @settingsDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get settingsDataSource;

  /// No description provided for @settingsDataSourceLiveApi.
  ///
  /// In en, this message translates to:
  /// **'Live API'**
  String get settingsDataSourceLiveApi;

  /// No description provided for @settingsDataSourceStatic.
  ///
  /// In en, this message translates to:
  /// **'Static (GitHub)'**
  String get settingsDataSourceStatic;

  /// No description provided for @settingsStaticBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Static data base URL'**
  String get settingsStaticBaseUrl;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @reportPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Party Report'**
  String get reportPartyTitle;

  /// No description provided for @reportCandidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate Report'**
  String get reportCandidateTitle;

  /// No description provided for @reportForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast Report'**
  String get reportForecastTitle;

  /// No description provided for @reportCoalitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Coalition Scenario Report'**
  String get reportCoalitionTitle;

  /// No description provided for @notAnOfficialResult.
  ///
  /// In en, this message translates to:
  /// **'This is a statistical forecast, not an official result.'**
  String get notAnOfficialResult;

  /// No description provided for @reportDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Generated by PLC Election Intelligence. Every figure is a model estimate with an explicit data cutoff and uncertainty range — see the Methodology screen for the full statistical methodology.'**
  String get reportDisclaimer;

  /// No description provided for @candidateDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Candidate detail requires a live or static data connection. Configure a data source in Settings.'**
  String get candidateDetailUnavailable;

  /// No description provided for @methodologyPollingAvgBody.
  ///
  /// In en, this message translates to:
  /// **'A weighted average of polls that ask the same \"if elections were held today\" question. Weight = recency × sample size × population type × pollster quality. We never average polls that asked differently-worded questions, and we never count the same poll twice.'**
  String get methodologyPollingAvgBody;

  /// No description provided for @methodologyForecastBody.
  ///
  /// In en, this message translates to:
  /// **'A Monte Carlo simulation built on the polling average, adding modeled uncertainty from house effects, turnout, and undecided voters. It reports a median and 50/80/95% ranges — never a single number presented as fact.'**
  String get methodologyForecastBody;

  /// No description provided for @methodologySeatAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Allocation'**
  String get methodologySeatAllocationTitle;

  /// No description provided for @methodologySeatAllocationBody.
  ///
  /// In en, this message translates to:
  /// **'Seats are allocated using the Sainte-Laguë method against the current, officially verified election rules (132 seats, 1% national threshold). The majority line is always computed as floor(total seats / 2) + 1 — for 132 seats, that is 67.'**
  String get methodologySeatAllocationBody;

  /// No description provided for @methodologyCandidateProbTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate Seat Probability'**
  String get methodologyCandidateProbTitle;

  /// No description provided for @methodologyCandidateProbBody.
  ///
  /// In en, this message translates to:
  /// **'Because this is a closed-list election, voters vote for a list, not an individual candidate. A candidate\'s probability of winning a seat is the probability that their list wins at least as many seats as their position on the list, from the same simulations used for the seat forecast. We never calculate or display an individual candidate vote share.'**
  String get methodologyCandidateProbBody;

  /// No description provided for @methodologyCoalitionLabBody.
  ///
  /// In en, this message translates to:
  /// **'Mathematical feasibility (the probability a set of lists reaches a majority) is computed directly from simulation data. Political compatibility — whether parties are willing to cooperate — is a separate, evidence-sourced assessment and is never presented as a calibrated probability unless the underlying methodology supports one.'**
  String get methodologyCoalitionLabBody;

  /// No description provided for @methodologyUncertaintyTitle.
  ///
  /// In en, this message translates to:
  /// **'Uncertainty & Model Health'**
  String get methodologyUncertaintyTitle;

  /// No description provided for @methodologyUncertaintyBody.
  ///
  /// In en, this message translates to:
  /// **'If the most recent high-quality poll is old, the forecast\'s uncertainty widens rather than staying artificially narrow. Every forecast carries a model version, dataset version, and data cutoff timestamp so it can be reproduced and audited.'**
  String get methodologyUncertaintyBody;

  /// No description provided for @methodologyFooter.
  ///
  /// In en, this message translates to:
  /// **'This product applies the same methodology to every party or list. It does not recommend how to vote and does not adjust results to favor any political outcome.'**
  String get methodologyFooter;

  /// No description provided for @pollingAverageExplanation.
  ///
  /// In en, this message translates to:
  /// **'Weighted average of polls asking the same \"if elections were held today\" question. Not a forecast — see Methodology for the weighting formula.'**
  String get pollingAverageExplanation;

  /// No description provided for @modelSimulationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Model {version} · {count} simulations'**
  String modelSimulationsLabel(String version, int count);

  /// No description provided for @whyThisChangedLabel.
  ///
  /// In en, this message translates to:
  /// **'Why this changed: {reason}'**
  String whyThisChangedLabel(String reason);

  /// No description provided for @medianSeatForecastLine.
  ///
  /// In en, this message translates to:
  /// **'Median-seat forecast. Majority line: {majority} of {total} seats.'**
  String medianSeatForecastLine(int majority, int total);

  /// No description provided for @fieldworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Fieldwork {start}–{end}'**
  String fieldworkLabel(String start, String end);

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @candidateListPendingForecast.
  ///
  /// In en, this message translates to:
  /// **'Candidate list and per-candidate seat probabilities are available once this party\'s electoral list is linked to a published forecast run.'**
  String get candidateListPendingForecast;

  /// No description provided for @settingsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsAlerts;

  /// No description provided for @settingsAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow parties, candidates, pollsters, governorates'**
  String get settingsAlertsSubtitle;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free · Premium · Professional (API access)'**
  String get settingsSubscriptionSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedLabel;

  /// No description provided for @justNowLabel.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNowLabel;

  /// No description provided for @minutesAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgoLabel(int minutes);

  /// No description provided for @hoursAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String hoursAgoLabel(int hours);

  /// No description provided for @forecastBadgeText.
  ///
  /// In en, this message translates to:
  /// **'FORECAST'**
  String get forecastBadgeText;

  /// No description provided for @seatsEightyRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'seats · 80% range {low}–{high}'**
  String seatsEightyRangeLabel(int low, int high);

  /// No description provided for @largestListProbShort.
  ///
  /// In en, this message translates to:
  /// **'Largest-list prob.'**
  String get largestListProbShort;

  /// No description provided for @majorityProbShort.
  ///
  /// In en, this message translates to:
  /// **'Majority prob.'**
  String get majorityProbShort;

  /// No description provided for @registrationStatusRumored.
  ///
  /// In en, this message translates to:
  /// **'Rumored'**
  String get registrationStatusRumored;

  /// No description provided for @registrationStatusConsidering.
  ///
  /// In en, this message translates to:
  /// **'Considering'**
  String get registrationStatusConsidering;

  /// No description provided for @registrationStatusAnnouncedIntention.
  ///
  /// In en, this message translates to:
  /// **'Announced Intention'**
  String get registrationStatusAnnouncedIntention;

  /// No description provided for @registrationStatusSubmittedRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration Submitted'**
  String get registrationStatusSubmittedRegistration;

  /// No description provided for @registrationStatusProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional'**
  String get registrationStatusProvisional;

  /// No description provided for @registrationStatusOfficiallyApproved.
  ///
  /// In en, this message translates to:
  /// **'Officially Approved'**
  String get registrationStatusOfficiallyApproved;

  /// No description provided for @registrationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get registrationStatusRejected;

  /// No description provided for @registrationStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get registrationStatusWithdrawn;

  /// No description provided for @registrationStatusDisqualified.
  ///
  /// In en, this message translates to:
  /// **'Disqualified'**
  String get registrationStatusDisqualified;

  /// No description provided for @confidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidenceLabel;

  /// No description provided for @jointListReportedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joint list reported'**
  String get jointListReportedLabel;

  /// No description provided for @jointListReportedTooltip.
  ///
  /// In en, this message translates to:
  /// **'At least one source reports these parties running on one shared electoral list — not a probability, see the evidence below.'**
  String get jointListReportedTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
