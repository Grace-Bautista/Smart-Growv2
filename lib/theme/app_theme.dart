import 'package:flutter/material.dart';

/// Central design tokens and component defaults for Smart-Grow.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF8B5E3C);
  static const Color primaryDark = Color(0xFF65432C);
  static const Color primaryLight = Color(0xFFB68C63);
  static const Color primaryContainer = Color(0xFFF2E8DF);
  static const Color surface = Color(0xFFF8F6F3);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF26231F);
  static const Color textSecondary = Color(0xFF746D66);
  static const Color divider = Color(0xFFE8E1DA);
  static const Color success = Color(0xFF388E5A);
  static const Color warning = Color(0xFFE49B35);
  static const Color danger = Color(0xFFD94B45);
  static const Color info = Color(0xFF527A91);

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static double adaptivePadding(double width) {
    if (width >= 1200) return space7;
    if (width >= 800) return space6;
    if (width >= 600) return space5;
    return space4;
  }

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primaryDark,
      secondary: primaryLight,
      onSecondary: textPrimary,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: primaryDark,
      tertiary: success,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      outline: divider,
      outlineVariant: divider,
      shadow: Color(0x1A26231F),
      scrim: Color(0x6626231F),
      inverseSurface: textPrimary,
      onInverseSurface: surface,
      inversePrimary: primaryLight,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSm),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(color: textPrimary, height: 1.4),
        bodyMedium: const TextStyle(color: textPrimary, height: 1.4),
        bodySmall: const TextStyle(color: textSecondary, height: 1.35),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space5,
            vertical: space4,
          ),
          shape: rounded,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: space5,
            vertical: space4,
          ),
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: space5,
            vertical: space4,
          ),
          side: const BorderSide(color: divider),
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, shape: rounded),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryContainer
              : divider,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(space1),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : textSecondary,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primaryDark
                : textSecondary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primaryContainer
                : cardSurface,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: divider)),
          shape: WidgetStatePropertyAll(rounded),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: primaryContainer,
        selectedColor: primary,
        side: const BorderSide(color: divider),
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardSurface,
        indicatorColor: primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      popupMenuTheme: PopupMenuThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(space2),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
      dividerColor: divider,
      splashFactory: InkRipple.splashFactory,
    );
  }

  static List<BoxShadow> softShadow({double opacity = 0.06}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> hoverShadow() => [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 28,
      offset: const Offset(0, 12),
      spreadRadius: -6,
    ),
  ];
}
