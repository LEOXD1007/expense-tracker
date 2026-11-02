import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const jade = Color(0xFF0E7C66);
  static const jadeDeep = Color(0xFF0A5C4C);
  static const expense = Color(0xFFE15A45);
  static const income = Color(0xFF1F9D55);
  static const warning = Color(0xFFC98412);
  static const page = Color(0xFFF3F5F2);

  static const palette = <int>[
    0xFFE25B45,
    0xFFD9892B,
    0xFFE0A100,
    0xFF2F8F6B,
    0xFF0E8A8A,
    0xFF3D7A9A,
    0xFF3E6FD8,
    0xFF7A5AF5,
    0xFFD4537E,
    0xFF8A6A3D,
    0xFF6B7280,
    0xFF334155,
  ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({String? fontFamily}) =>
      _build(Brightness.light, fontFamily);

  static ThemeData dark({String? fontFamily}) =>
      _build(Brightness.dark, fontFamily);

  static ThemeData _build(Brightness brightness, String? fontFamily) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.jade,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.page
          : scheme.surface,
    );
    final textTheme = fontFamily == null
        ? base.textTheme
        : base.textTheme.apply(fontFamily: fontFamily);
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: fontFamily == null
          ? base.primaryTextTheme
          : base.primaryTextTheme.apply(fontFamily: fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
