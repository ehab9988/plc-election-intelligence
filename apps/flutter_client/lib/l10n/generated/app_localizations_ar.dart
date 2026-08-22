// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'استخبارات الانتخابات التشريعية';

  @override
  String get navDashboard => 'لوحة المعلومات';

  @override
  String get navForecast => 'التوقعات';

  @override
  String get navParliament => 'المجلس';

  @override
  String get navPolls => 'استطلاعات الرأي';

  @override
  String get navParties => 'الأحزاب';

  @override
  String get navCoalitionLab => 'مختبر الائتلافات';

  @override
  String get navNews => 'الأخبار';

  @override
  String get navMethodology => 'المنهجية';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get electionCountdown => 'يوم الانتخابات';

  @override
  String forecastUpdated(String time) {
    return 'تم تحديث التوقعات $time';
  }

  @override
  String dataCutoff(String time) {
    return 'تاريخ قطع البيانات: $time';
  }

  @override
  String get largestListProbability => 'احتمال أن تكون القائمة الأكبر';

  @override
  String get medianSeats => 'الوسيط للمقاعد';

  @override
  String get range80 => 'نطاق 80٪';

  @override
  String get range95 => 'نطاق 95٪';

  @override
  String get voteShareMedian => 'نسبة الأصوات (الوسيط)';

  @override
  String get probabilityMajority => 'احتمال الأغلبية المنفردة';

  @override
  String get probabilityThreshold => 'احتمال تجاوز العتبة القانونية';

  @override
  String get pollingAverage => 'متوسط استطلاعات الرأي';

  @override
  String get nowcast => 'التقدير الحالي';

  @override
  String get electionDayForecast => 'توقع يوم الانتخابات';

  @override
  String majorityLine(int seats) {
    return 'الأغلبية: $seats مقعدًا';
  }

  @override
  String get seatProbability =>
      'الاحتمال التقديري للفوز بمقعد في المجلس التشريعي';

  @override
  String listRank(int rank) {
    return 'الترتيب على القائمة: #$rank';
  }

  @override
  String get viewSource => 'عرض المصدر';

  @override
  String get sources => 'المصادر';

  @override
  String get registrationStatus => 'حالة التسجيل';

  @override
  String verifiedOn(String date) {
    return 'تم التحقق بتاريخ $date';
  }

  @override
  String get undecided => 'غير محدد';

  @override
  String get coalitionLabTitle => 'مختبر الائتلافات';

  @override
  String get coalitionLabHint => 'اختر القوائم لبناء سيناريو ائتلاف';

  @override
  String get combinedSeats => 'مجموع المقاعد';

  @override
  String get majorityProbability => 'احتمال الوصول إلى الأغلبية';

  @override
  String get methodologyTitle => 'المنهجية';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get forecastVsResults => 'توقع — وليس نتيجة رسمية';

  @override
  String get insufficientData => 'بيانات غير كافية';

  @override
  String get demoDataBanner =>
      'تُعرض بيانات تجريبية مضمّنة — اتصل بواجهة برمجة تطبيقات حية من الإعدادات للاستخدام الفعلي.';

  @override
  String elevatedUncertainty(String reason) {
    return 'درجة عدم اليقين في التوقع مرتفعة: $reason';
  }

  @override
  String get searchHint => 'ابحث عن الأحزاب، المرشحين، الاستطلاعات…';

  @override
  String get candidateBiography => 'السيرة الذاتية';

  @override
  String get candidateGovernorate => 'المحافظة';

  @override
  String get candidateHometown => 'البلدة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get noData => 'لا توجد بيانات متاحة بعد';

  @override
  String get navMore => 'المزيد';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get generatingReport => 'جارٍ إنشاء التقرير…';

  @override
  String get reportGenerated => 'التقرير جاهز';

  @override
  String get projectedLargestList => 'القائمة الأكبر المتوقعة';

  @override
  String get viewFullForecast => 'عرض التوقع الكامل';

  @override
  String get latestPolls => 'أحدث الاستطلاعات';

  @override
  String get latestForecastTitle => 'أحدث التوقعات';

  @override
  String get dataCutoffLabel => 'تاريخ قطع البيانات';

  @override
  String get electionDay => 'يوم الانتخابات';

  @override
  String daysUntilElection(int days) {
    return '$days يومًا حتى يوم الانتخابات';
  }

  @override
  String get newsTitle => 'الأخبار';

  @override
  String get pollsTitle => 'استطلاعات الرأي';

  @override
  String get partiesTitle => 'الأحزاب';

  @override
  String get candidatesTitle => 'المرشحون';

  @override
  String generatedOn(String date) {
    return 'تم الإنشاء بتاريخ $date';
  }

  @override
  String get modelVersionLabel => 'إصدار النموذج';

  @override
  String get seatsLabel => 'المقاعد';

  @override
  String get voteShareLabel => 'نسبة الأصوات';

  @override
  String get sourceCitationsHeading => 'المصادر المرجعية';

  @override
  String get politicalCompatibilityEvidence => 'أدلة التوافق السياسي';

  @override
  String get mathematicalFeasibilityNote =>
      'جدوى رياضية فقط — يُعرض التوافق السياسي بشكل منفصل ولا يُقدَّم أبدًا كاحتمال تشكيل ائتلاف.';

  @override
  String get settingsDemoMode => 'وضع تجريبي (بيانات نموذجية مضمّنة)';

  @override
  String get settingsApiBaseUrl => 'رابط واجهة البرمجة';

  @override
  String get settingsSave => 'حفظ';

  @override
  String get reportPartyTitle => 'تقرير الحزب';

  @override
  String get reportCandidateTitle => 'تقرير المرشح';

  @override
  String get reportForecastTitle => 'تقرير التوقعات';

  @override
  String get reportCoalitionTitle => 'تقرير سيناريو الائتلاف';

  @override
  String get notAnOfficialResult => 'هذا توقع إحصائي وليس نتيجة رسمية.';

  @override
  String get reportDisclaimer =>
      'تم إنشاؤه بواسطة تطبيق استخبارات الانتخابات التشريعية. كل رقم هو تقدير نموذجي له تاريخ قطع بيانات محدد ونطاق عدم يقين — راجع صفحة المنهجية للاطلاع على المنهجية الإحصائية الكاملة.';
}
