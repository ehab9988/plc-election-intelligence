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
  String get settingsApiBaseUrl => 'رابط واجهة البرمجة';

  @override
  String get settingsDataSource => 'مصدر البيانات';

  @override
  String get settingsDataSourceLiveApi => 'واجهة برمجة مباشرة';

  @override
  String get settingsDataSourceStatic => 'ثابت (GitHub)';

  @override
  String get settingsStaticBaseUrl => 'رابط بيانات GitHub الثابتة';

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

  @override
  String get candidateDetailUnavailable =>
      'تفاصيل المرشح تتطلب اتصالاً حيًا أو ببيانات ثابتة. يرجى ضبط مصدر البيانات من الإعدادات.';

  @override
  String get methodologyPollingAvgBody =>
      'متوسط مرجّح لاستطلاعات الرأي التي تطرح نفس سؤال \"لو أجريت الانتخابات اليوم\". الوزن = الحداثة × حجم العينة × نوع الفئة السكانية × جودة جهة الاستطلاع. لا يتم أبدًا حساب متوسط استطلاعات صيغت بأسئلة مختلفة، ولا يُحتسب أي استطلاع مرتين.';

  @override
  String get methodologyForecastBody =>
      'محاكاة مونت كارلو مبنية على متوسط الاستطلاعات، مع إضافة عدم يقين نمذجي ناتج عن تأثيرات الجهة المنظمة، ونسبة المشاركة، والناخبين غير الحاسمين. يُعرض الوسيط ونطاقات 50%/80%/95% — وليس رقمًا واحدًا يُقدَّم كحقيقة.';

  @override
  String get methodologySeatAllocationTitle => 'توزيع المقاعد';

  @override
  String get methodologySeatAllocationBody =>
      'تُوزَّع المقاعد باستخدام طريقة سانت ليغو وفق قواعد الانتخابات الرسمية المعتمدة حاليًا (132 مقعدًا، عتبة وطنية 1%). خط الأغلبية يُحسب دائمًا كـ: (إجمالي المقاعد ÷ 2) + 1 — أي 67 مقعدًا من أصل 132.';

  @override
  String get methodologyCandidateProbTitle => 'احتمال فوز المرشح بمقعد';

  @override
  String get methodologyCandidateProbBody =>
      'بما أن هذه انتخابات بنظام القائمة المغلقة، فإن الناخب يصوّت لقائمة وليس لمرشح فردي. احتمال فوز المرشح بمقعد هو احتمال أن تفوز قائمته بعدد مقاعد لا يقل عن ترتيبه ضمن القائمة، استنادًا إلى نفس عمليات المحاكاة المستخدمة في توقع المقاعد. لا يتم أبدًا حساب أو عرض نسبة تصويت فردية لمرشح.';

  @override
  String get methodologyCoalitionLabBody =>
      'الجدوى الرياضية (احتمال وصول مجموعة من القوائم إلى الأغلبية) تُحسب مباشرة من بيانات المحاكاة. أما التوافق السياسي — مدى استعداد الأحزاب للتعاون — فهو تقييم منفصل مستند إلى أدلة، ولا يُعرض أبدًا كاحتمال معايَر ما لم تدعمه منهجية إحصائية فعلية.';

  @override
  String get methodologyUncertaintyTitle => 'عدم اليقين وسلامة النموذج';

  @override
  String get methodologyUncertaintyBody =>
      'إذا كان آخر استطلاع عالي الجودة قديمًا، يتسع نطاق عدم اليقين في التوقع بدلاً من أن يبقى ضيقًا بشكل مصطنع. يحمل كل توقع رقم إصدار النموذج، وإصدار مجموعة البيانات، وطابعًا زمنيًا لتاريخ قطع البيانات، بحيث يمكن إعادة إنتاجه ومراجعته.';

  @override
  String get methodologyFooter =>
      'يطبّق هذا المنتج نفس المنهجية على كل حزب أو قائمة. لا يُوصي بكيفية التصويت ولا يُعدِّل النتائج لصالح أي اتجاه سياسي.';

  @override
  String get pollingAverageExplanation =>
      'متوسط مرجّح لاستطلاعات الرأي التي تطرح نفس سؤال \"لو أجريت الانتخابات اليوم\". هذا ليس توقعًا — راجع صفحة المنهجية لمعرفة صيغة الترجيح.';

  @override
  String modelSimulationsLabel(String version, int count) {
    return 'النموذج $version · $count محاكاة';
  }

  @override
  String whyThisChangedLabel(String reason) {
    return 'سبب هذا التغيير: $reason';
  }

  @override
  String medianSeatForecastLine(int majority, int total) {
    return 'توقع وسيط المقاعد. خط الأغلبية: $majority من أصل $total مقعدًا.';
  }

  @override
  String fieldworkLabel(String start, String end) {
    return 'ميدان العمل $start–$end';
  }

  @override
  String get verifiedLabel => 'موثّق';

  @override
  String get candidateListPendingForecast =>
      'ستتوفر قائمة المرشحين واحتمالات فوزهم بمقاعد فردية بمجرد ربط القائمة الانتخابية لهذا الحزب بتوقع منشور.';

  @override
  String get settingsAlerts => 'التنبيهات';

  @override
  String get settingsAlertsSubtitle =>
      'متابعة الأحزاب والمرشحين وجهات الاستطلاع والمحافظات';

  @override
  String get settingsSubscription => 'الاشتراك';

  @override
  String get settingsSubscriptionSubtitle =>
      'مجاني · مميز · احترافي (وصول لواجهة البرمجة)';

  @override
  String get settingsPrivacy => 'الخصوصية';

  @override
  String get updatedLabel => 'تحديث';

  @override
  String get justNowLabel => 'الآن';

  @override
  String minutesAgoLabel(int minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String hoursAgoLabel(int hours) {
    return 'قبل $hours ساعة';
  }

  @override
  String get forecastBadgeText => 'توقع';

  @override
  String seatsEightyRangeLabel(int low, int high) {
    return 'مقعدًا · نطاق 80%: $low–$high';
  }

  @override
  String get largestListProbShort => 'احتمال الصدارة';

  @override
  String get majorityProbShort => 'احتمال الأغلبية';

  @override
  String get registrationStatusRumored => 'إشاعة';

  @override
  String get registrationStatusConsidering => 'قيد الدراسة';

  @override
  String get registrationStatusAnnouncedIntention => 'أُعلنت النية';

  @override
  String get registrationStatusSubmittedRegistration => 'قُدّم طلب التسجيل';

  @override
  String get registrationStatusProvisional => 'مؤقت';

  @override
  String get registrationStatusOfficiallyApproved => 'معتمد رسميًا';

  @override
  String get registrationStatusRejected => 'مرفوض';

  @override
  String get registrationStatusWithdrawn => 'منسحب';

  @override
  String get registrationStatusDisqualified => 'مستبعد';

  @override
  String get confidenceLabel => 'درجة الثقة';

  @override
  String get jointListReportedLabel => 'قائمة مشتركة مُبلَّغ عنها';

  @override
  String get jointListReportedTooltip =>
      'أفاد مصدر واحد على الأقل بأن هذين الحزبين سيخوضان الانتخابات بقائمة انتخابية واحدة مشتركة — هذا ليس احتمالاً إحصائيًا، راجع الأدلة أدناه.';

  @override
  String get aiFormationEstimatesTitle => 'تقديرات الائتلاف بالذكاء الاصطناعي';

  @override
  String get aiEstimateDisclaimer =>
      'تقدير خاص بنموذج لغوي مستند إلى بحث على الويب — وليس إحصاءً معايَرًا كالجدوى الرياضية أعلاه. تعامل معه كمؤشر تقريبي لا كحقيقة.';

  @override
  String get aiEstimateLabel => 'تقدير الذكاء الاصطناعي';
}
