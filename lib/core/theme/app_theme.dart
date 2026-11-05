import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.pinkStrong,
      onPrimary: AppColors.charcoal,
      primaryContainer: AppColors.pink,
      onPrimaryContainer: AppColors.charcoal,
      secondary: AppColors.blueStrong,
      onSecondary: AppColors.charcoal,
      secondaryContainer: AppColors.blue,
      onSecondaryContainer: AppColors.charcoal,
      error: Color(0xFFB3261E),
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.charcoal,
      surfaceContainerLowest: AppColors.offWhite,
      outline: AppColors.charcoal,
      outlineVariant: Color(0xFFD9D9DE),
    );
    return _build(scheme, background: AppColors.offWhite);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.pinkStrong,
      onPrimary: AppColors.charcoal,
      primaryContainer: Color(0xFF5A3F45),
      onPrimaryContainer: AppColors.pink,
      secondary: AppColors.blueStrong,
      onSecondary: AppColors.charcoal,
      secondaryContainer: Color(0xFF3A4660),
      onSecondaryContainer: AppColors.blue,
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: AppColors.darkSurface,
      onSurface: AppColors.offWhite,
      surfaceContainerLowest: AppColors.darkBackground,
      outline: Color(0xFF8E8E96),
      outlineVariant: Color(0xFF45454D),
    );
    return _build(scheme, background: AppColors.darkBackground);
  }

  static ThemeData _build(ColorScheme scheme, {required Color background}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
