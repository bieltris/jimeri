import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Inter';
  static const List<String> fontFallback = ['Segoe UI', 'Arial', 'sans-serif'];

  static ThemeData get lightTheme {
    return _baseTheme(
      brightness: Brightness.light,
      background: AppColors.neutral50,
      surface: Colors.white,
      text: AppColors.neutral950,
      mutedText: AppColors.neutral600,
      border: AppColors.neutral300,
    );
  }

  static ThemeData get darkTheme {
    return _baseTheme(
      brightness: Brightness.dark,
      background: AppColors.neutral950,
      surface: AppColors.neutral800,
      text: AppColors.neutral50,
      mutedText: AppColors.neutral300,
      border: AppColors.neutral600,
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color mutedText,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: surface,
      error: AppColors.error,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(brightness, text, mutedText),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(
    Brightness brightness,
    Color text,
    Color mutedText,
  ) {
    final base = ThemeData(
      brightness: brightness,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      useMaterial3: true,
    ).textTheme;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: text,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: mutedText),
      bodyMedium: base.bodyMedium?.copyWith(color: mutedText),
    );
  }
}
