import 'package:flutter/material.dart';
import 'package:finalyearproject/core/constants/app_colors.dart';
import 'package:finalyearproject/core/constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // Typography: Centralized in AppTextStyles
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // Card Theme: Soft radiuses and tonal separation
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration: No borders, tonal background
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.outline),
      ),

      // Button Theme: Minimalist and pill-shaped
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Bottom Navigation: Subtle and clean
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.transparent, // "No-Line" Rule
        space: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppDarkColors.primary,
        onPrimary: AppDarkColors.onPrimary,
        primaryContainer: AppDarkColors.primaryContainer,
        secondary: AppDarkColors.secondary,
        onSecondary: AppDarkColors.onSecondary,
        secondaryContainer: AppDarkColors.secondaryContainer,
        error: AppDarkColors.error,
        onError: Colors.black,
        surface: AppDarkColors.surface,
        onSurface: AppDarkColors.onSurface,
        onSurfaceVariant: AppDarkColors.onSurfaceVariant,
        outline: AppDarkColors.outline,
        outlineVariant: AppDarkColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppDarkColors.background,

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppDarkColors.textPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppDarkColors.textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppDarkColors.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppDarkColors.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppDarkColors.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppDarkColors.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppDarkColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppDarkColors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppDarkColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppDarkColors.textPrimary),
        hintStyle: AppTextStyles.labelMedium.copyWith(color: AppDarkColors.outline),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: AppDarkColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDarkColors.surface,
        selectedItemColor: AppDarkColors.primary,
        unselectedItemColor: AppDarkColors.outline,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      dividerTheme: const DividerThemeData(
        color: Colors.transparent, // "No-Line" Rule
        space: 24,
      ),
    );
  }
}
