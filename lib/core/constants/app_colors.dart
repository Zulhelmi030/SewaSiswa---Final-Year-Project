import 'package:flutter/material.dart';

/// Design System: "The Academic Curator"
/// Source: RumahUntukPelajar PRD — Google Stitch
/// Theme: Deep Blue (academic authority) + Warm Orange (student energy)
/// Color Mode: LIGHT
class AppColors {
  // ── Primary (Deep Blue) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF002653);
  static const Color primaryContainer = Color(0xFF1A3C6E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF8AA8E0);
  static const Color primaryFixed = Color(0xFFD7E3FF);
  static const Color primaryFixedDim = Color(0xFFABC7FF);
  static const Color onPrimaryFixed = Color(0xFF001B3F);
  static const Color onPrimaryFixedVariant = Color(0xFF264679);
  static const Color inversePrimary = Color(0xFFABC7FF);

  // ── Secondary (Warm Orange) ───────────────────────────────────────────────
  static const Color secondary = Color(0xFF914D00);
  static const Color secondaryContainer = Color(0xFFFC9430);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF663500);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF3E1F00);
  static const Color tertiaryContainer = Color(0xFF5E3100);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFDB9960);
  static const Color tertiaryFixed = Color(0xFFFFDCC2);
  static const Color tertiaryFixedDim = Color(0xFFFEB87C);
  static const Color onTertiaryFixed = Color(0xFF2E1500);
  static const Color onTertiaryFixedVariant = Color(0xFF6B3B09);

  // ── Background & Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF43474F);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  // ── Surface Containers (Tonal Layering — "No-Line" rule) ─────────────────
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color surfaceTint = Color(0xFF405E92);

  // ── Neutral & Utility ────────────────────────────────────────────────────
  static const Color outline = Color(0xFF747780);
  static const Color outlineVariant = Color(0xFFC4C6D0);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF10B981);

  // ── Text Colors (Semantic aliases) ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF43474F);

  // ── Signature Gradient (Hero & CTAs) ─────────────────────────────────────
  /// primary (#002653) → primaryContainer (#1A3C6E) at 135°
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159 / 180),
    colors: [Color(0xFF002653), Color(0xFF1A3C6E)],
  );
}
