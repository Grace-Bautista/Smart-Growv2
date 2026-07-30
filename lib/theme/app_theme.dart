import 'package:flutter/material.dart';

/// Centralised design tokens + [ThemeData] for the SmartGrow dashboard.
///
/// Keeping colours, radii and spacing here means every widget in the app
/// pulls from a single source of truth instead of hard-coded magic numbers.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Palette
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF8B5E3C); // brown (header)
  static const Color primaryLight = Color(0xFFB68C63); // light brown 
  static const Color primaryDark = Color.fromARGB(255, 52, 85, 194); 
  static const Color surface = Color(0xFFF7F5F2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF34A853);
  static const Color danger = Color(0xFFE0432B);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF7A7F8C);
  static const Color divider = Color(0xFFE7E4E0);

  // ---------------------------------------------------------------------
  // 8-point spacing scale
  // ---------------------------------------------------------------------
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 26;

  /// Returns responsive horizontal page padding based on available width.
  static double adaptivePadding(double width) {
    if (width >= 1200) return space7;
    if (width >= 800) return space6;
    if (width >= 600) return space5;
    return space4;
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(color: textSecondary, height: 1.35),
        bodySmall: const TextStyle(color: textSecondary),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      splashFactory: InkRipple.splashFactory,
    );
  }

  /// Soft elevation shadow reused across every card in the app.
  static List<BoxShadow> softShadow({double opacity = 0.06}) => [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  /// Slightly stronger shadow used on hover (web/desktop) for affordance.
  static List<BoxShadow> hoverShadow() => [
        BoxShadow(
          color: primary.withOpacity(0.18),
          blurRadius: 28,
          offset: const Offset(0, 12),
          spreadRadius: -6,
        ),
      ];
}
