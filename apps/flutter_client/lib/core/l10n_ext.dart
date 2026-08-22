import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Whether the active locale is Arabic — use to pick which of a
  /// bilingual data pair (nameAr/nameEn, etc.) displays as primary vs.
  /// secondary, so switching to Arabic doesn't leave English as the
  /// dominant name everywhere.
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  /// Picks the locale-appropriate primary name from a bilingual pair —
  /// Arabic first when the active locale is Arabic, English otherwise.
  String primaryName({required String en, required String ar}) => isArabic ? ar : en;

  /// The other half of [primaryName] — whichever name ISN'T primary,
  /// for a secondary/subtitle display.
  String secondaryName({required String en, required String ar}) => isArabic ? en : ar;
}
