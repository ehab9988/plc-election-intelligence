import 'package:flutter/material.dart';

/// Bloomberg-terminal-adjacent, information-dense but clean design system
/// (spec section 46). Colors are chosen for colorblind-safe contrast; list
/// colors from the API are only ever used as accents, never as the sole
/// way to distinguish a series (always paired with a label/legend).
class AppTheme {
  static const _seed = Color(0xFF14532D);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(backgroundColor: scheme.surface),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}

/// Semantic colors that never rely on hue alone (accessibility, section
/// 46/71): each also carries a distinct icon/shape in the widgets that use
/// them.
class SemanticColors {
  static const uncertaintyBand = Color(0x332196F3);
  static const majorityLine = Color(0xFFE53935);
  static const forecastLabel = Color(0xFF616161);
  static const officialResultLabel = Color(0xFF14532D);
}
