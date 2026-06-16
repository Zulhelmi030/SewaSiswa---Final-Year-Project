import 'package:flutter/material.dart';
import 'package:finalyearproject/core/constants/app_colors.dart';
import 'package:finalyearproject/core/constants/app_text_styles.dart';

class ThemeColors {
  final BuildContext context;
  ThemeColors(this.context);
  
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get primary => _isDark ? AppDarkColors.primary : AppColors.primary;
  Color get primaryContainer => _isDark ? AppDarkColors.primaryContainer : AppColors.primaryContainer;
  Color get onPrimary => _isDark ? AppDarkColors.onPrimary : AppColors.onPrimary;
  Color get onPrimaryContainer => _isDark ? AppDarkColors.onPrimaryContainer : AppColors.onPrimaryContainer;
  Color get primaryFixed => AppColors.primaryFixed;
  Color get primaryFixedDim => AppColors.primaryFixedDim;
  Color get onPrimaryFixed => AppColors.onPrimaryFixed;
  Color get onPrimaryFixedVariant => AppColors.onPrimaryFixedVariant;
  Color get inversePrimary => AppColors.inversePrimary;
  
  Color get secondary => _isDark ? AppDarkColors.secondary : AppColors.secondary;
  Color get secondaryContainer => _isDark ? AppDarkColors.secondaryContainer : AppColors.secondaryContainer;
  Color get onSecondary => _isDark ? AppDarkColors.onSecondary : AppColors.onSecondary;
  Color get onSecondaryContainer => _isDark ? AppDarkColors.onSecondaryContainer : AppColors.onSecondaryContainer;
  Color get secondaryFixed => AppColors.secondaryFixed;
  Color get secondaryFixedDim => AppColors.secondaryFixedDim;
  Color get onSecondaryFixed => AppColors.onSecondaryFixed;
  Color get onSecondaryFixedVariant => AppColors.onSecondaryFixedVariant;
  
  Color get tertiary => _isDark ? AppDarkColors.tertiary : AppColors.tertiary;
  Color get tertiaryContainer => _isDark ? AppDarkColors.tertiaryContainer : AppColors.tertiaryContainer;
  Color get onTertiary => _isDark ? AppDarkColors.onTertiary : AppColors.onTertiary;
  Color get onTertiaryContainer => _isDark ? AppDarkColors.onTertiaryContainer : AppColors.onTertiaryContainer;
  Color get tertiaryFixed => AppColors.tertiaryFixed;
  Color get tertiaryFixedDim => AppColors.tertiaryFixedDim;
  Color get onTertiaryFixed => AppColors.onTertiaryFixed;
  Color get onTertiaryFixedVariant => AppColors.onTertiaryFixedVariant;

  Color get warning => _isDark ? AppDarkColors.warning : AppColors.warning;
  Color get warningContainer => _isDark ? AppDarkColors.warningContainer : AppColors.warningContainer;

  Color get background => _isDark ? AppDarkColors.background : AppColors.background;
  Color get surface => _isDark ? AppDarkColors.surface : AppColors.surface;
  Color get surfaceDim => AppColors.surfaceDim;
  Color get surfaceBright => AppColors.surfaceBright;
  Color get onSurface => _isDark ? AppDarkColors.onSurface : AppColors.onSurface;
  Color get onSurfaceVariant => _isDark ? AppDarkColors.onSurfaceVariant : AppColors.onSurfaceVariant;
  Color get inverseSurface => AppColors.inverseSurface;
  Color get inverseOnSurface => AppColors.inverseOnSurface;
  
  Color get surfaceContainerLowest => _isDark ? AppDarkColors.surfaceContainerLowest : AppColors.surfaceContainerLowest;
  Color get surfaceContainerLow => _isDark ? AppDarkColors.surfaceContainerLow : AppColors.surfaceContainerLow;
  Color get surfaceContainer => _isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainer;
  Color get surfaceContainerHigh => AppColors.surfaceContainerHigh;
  Color get surfaceContainerHighest => AppColors.surfaceContainerHighest;
  Color get surfaceVariant => AppColors.surfaceVariant;
  Color get surfaceTint => AppColors.surfaceTint;
  
  Color get outline => _isDark ? AppDarkColors.outline : AppColors.outline;
  Color get glassOutline => _isDark ? AppDarkColors.glassOutline : AppColors.glassOutline;
  Color get outlineVariant => _isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant;
  
  Color get error => _isDark ? AppDarkColors.error : AppColors.error;
  Color get errorContainer => AppColors.errorContainer;
  Color get onError => AppColors.onError;
  Color get onErrorContainer => AppColors.onErrorContainer;
  Color get success => AppColors.success;
  
  Color get textPrimary => _isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  Color get textSecondary => _isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  
  LinearGradient get primaryGradient => AppColors.primaryGradient;
  LinearGradient get actionGradient => AppColors.actionGradient;
}

class ThemeTextStyles {
  final BuildContext context;
  ThemeTextStyles(this.context);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  TextStyle get displayLarge => _isDark ? AppTextStyles.displayLarge.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.displayLarge;
  TextStyle get headlineLarge => _isDark ? AppTextStyles.headlineLarge.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.headlineLarge;
  TextStyle get headlineMedium => _isDark ? AppTextStyles.headlineMedium.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.headlineMedium;
  TextStyle get headlineSmall => _isDark ? AppTextStyles.headlineSmall.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.headlineSmall;
  TextStyle get titleLarge => _isDark ? AppTextStyles.titleLarge.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.titleLarge;
  TextStyle get titleMedium => _isDark ? AppTextStyles.titleMedium.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.titleMedium;
  TextStyle get bodyLarge => _isDark ? AppTextStyles.bodyLarge.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.bodyLarge;
  TextStyle get bodyMedium => _isDark ? AppTextStyles.bodyMedium.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.bodyMedium;
  TextStyle get bodySmall => _isDark ? AppTextStyles.bodySmall.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.bodySmall;
  TextStyle get labelMedium => _isDark ? AppTextStyles.labelMedium.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.labelMedium;
  TextStyle get labelSmall => _isDark ? AppTextStyles.labelSmall.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.labelSmall;
  TextStyle get labelCaps => _isDark ? AppTextStyles.labelCaps.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.labelCaps;
}

extension AppThemeExtension on BuildContext {
  ThemeColors get appColors => ThemeColors(this);
  ThemeTextStyles get appTextStyles => ThemeTextStyles(this);
}
