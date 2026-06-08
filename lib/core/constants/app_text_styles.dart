import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography System: "The Academic Curator"
/// Source: RumahUntukPelajar PRD — Google Stitch
///
/// Dual-typeface system:
///   Headline/Display → Manrope (geometric precision, modern warmth)
///   Body/Labels      → Inter  (workhorse, screen-optimized legibility)
class AppTextStyles {
  // ── Display — Manrope ────────────────────────────────────────────────────
  /// Hero statements: 3.5rem / 700 / tight leading
  static TextStyle get displayLarge => GoogleFonts.manrope(
        fontSize: 56,        // ~3.5rem
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.12, // -0.02em
        color: AppColors.textPrimary,
      );

  // ── Headlines — Manrope ──────────────────────────────────────────────────
  /// Section titles: 1.75rem / 600
  static TextStyle get headlineLarge => GoogleFonts.manrope(
        fontSize: 28,        // ~1.75rem
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.28, // -0.01em
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ── Titles — Inter ───────────────────────────────────────────────────────
  /// Property names / card titles: 1.375rem / 600
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,        // ~1.375rem
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ── Body — Inter ─────────────────────────────────────────────────────────
  /// Descriptions: 0.875rem / 400
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,        // 0.875rem per spec
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ── Labels — Inter ───────────────────────────────────────────────────────
  /// Metadata & Tags: 0.75rem / 500
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,        // 0.75rem
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  /// Uppercase overline label (for section markers like "CURATED")
  static TextStyle get labelCaps => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 2.0, // wide tracking for caps
        color: AppColors.textSecondary,
      );
}
