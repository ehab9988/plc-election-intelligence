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

  /// No description provided for @settingsDataSourceDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo (bundled sample data)'**
  String get settingsDataSourceDemo;

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
