import 'package:flutter/material.dart';

/// Design System: "The Academic Curator"
/// Source: RumahUntukPelajar PRD — Google Stitch
/// Theme: Sapphire-Indigo (academic authority) + Burnt-Tangerine (student energy)
/// Color Mode: LIGHT
class AppColors {
  // ── Primary (Sapphire-Indigo) ────────────────────────────────────────────
  static const Color primary = Color(0xFF1B3A8C);
  static const Color primaryContainer = Color(0xFFDCE4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1B3A8C);
  static const Color primaryFixed = Color(0xFFD7E3FF);
  static const Color primaryFixedDim = Color(0xFFABC7FF);
  static const Color onPrimaryFixed = Color(0xFF001B3F);
  static const Color onPrimaryFixedVariant = Color(0xFF264679);
  static const Color inversePrimary = Color(0xFFABC7FF);

  // ── Secondary (Burnt-Tangerine) ──────────────────────────────────────────
  static const Color secondary = Color(0xFFC2410C);
  static const Color secondaryContainer = Color(0xFFFF8C42);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF7A2E0A);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  // ── Tertiary (Mint Trust) ────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF0E8A6D);
  static const Color tertiaryContainer = Color(0xFFBFF3E2);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF0E8A6D);
  static const Color tertiaryFixed = Color(0xFFFFDCC2);
  static const Color tertiaryFixedDim = Color(0xFFFEB87C);
  static const Color onTertiaryFixed = Color(0xFF2E1500);
  static const Color onTertiaryFixedVariant = Color(0xFF6B3B09);

  // ── Warning (Pending/Action Needed) ──────────────────────────────────────
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningContainer = Color(0xFFFFF3D6);

  // ── Background & Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFF7F8FC);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceBright = Color(0xFFF7F8FC);
  static const Color onSurface = Color(0xFF12151C);
  static const Color onSurfaceVariant = Color(0xFF565B6E);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  // ── Surface Containers ───────────────────────────────────────────────────
  static const Color surfaceContainerLowest = Color(0xB8FFFFFF); // 72% opacity
  static const Color surfaceContainerLow = Color(0xFFEEF1FA);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color surfaceTint = Color(0xFF405E92);

  // ── Neutral & Utility ────────────────────────────────────────────────────
  static const Color outline = Color(0xFF747780);
  static const Color glassOutline = Color(0xFFE3E6F0);
  static const Color outlineVariant = Color(0xFFC4C6D0);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF10B981);

  // ── Text Colors (Semantic aliases) ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF12151C);
  static const Color textSecondary = Color(0xFF565B6E);

  // ── Signature Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159 / 180),
    colors: [Color(0xFF14296B), Color(0xFF2A46C9), Color(0xFF6E4FF0)],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159 / 180),
    colors: [Color(0xFFFF8C42), Color(0xFFC2410C)],
  );
}

/// Color Mode: DARK
class AppDarkColors {
  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF9DB4FF);
  static const Color primaryContainer = Color(0xFF243B82);
  static const Color onPrimary = Color(0xFF14296B);
  static const Color onPrimaryContainer = Color(0xFFDCE4FF);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFFF9A5C);
  static const Color secondaryContainer = Color(0xFF7A3A12);
  static const Color onSecondary = Color(0xFF4A1B0C);
  static const Color onSecondaryContainer = Color(0xFFFFD9B8);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF57E6C2);
  static const Color tertiaryContainer = Color(0xFF0F4A3C);
  static const Color onTertiary = Color(0xFF0F4A3C);
  static const Color onTertiaryContainer = Color(0xFFBFF3E2);

  // ── Warning ──────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFFFCB66);
  static const Color warningContainer = Color(0xFF3D2E0A);

  // ── Background & Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFF0B0E1A);
  static const Color surface = Color(0xFF0B0E1A);
  static const Color surfaceContainerLowest = Color(0xA61B2030); // 65% opacity
  static const Color surfaceContainerLow = Color(0xFF141829);
  static const Color surfaceContainer = Color(0xFF2C2C2E);
  static const Color onSurface = Color(0xFFEEF0F6);
  static const Color onSurfaceVariant = Color(0xFFC4C6D0);

  // ── Neutral & Utility ────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8A8D99);
  static const Color glassOutline = Color(0x14FFFFFF); // 8% opacity white
  static const Color outlineVariant = Color(0xFF44474E);
  static const Color error = Color(0xFFFFB4AB);
  
  // ── Text Colors (Semantic aliases) ───────────────────────────────────────
  static const Color textPrimary = Color(0xFFEEF0F6);
  static const Color textSecondary = Color(0xFF9AA0B8);
}
