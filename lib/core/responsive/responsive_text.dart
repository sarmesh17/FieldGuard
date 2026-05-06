import 'package:flutter/material.dart';
import 'size_config.dart';

/// Scalable typography that adapts to screen size and respects system
/// text scaling preferences.
class AppTextStyles {
  AppTextStyles._();

  // ─── Headings ─────────────────────────────────────────────────────────────

  static TextStyle get displayLarge => TextStyle(
        fontSize: SizeConfig.scaledFontSize(34),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: SizeConfig.scaledFontSize(28),
        fontWeight: FontWeight.bold,
        height: 1.3,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontSize: SizeConfig.scaledFontSize(24),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: SizeConfig.scaledFontSize(20),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => TextStyle(
        fontSize: SizeConfig.scaledFontSize(16),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: SizeConfig.scaledFontSize(14),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: SizeConfig.scaledFontSize(12),
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  // ─── Labels & Captions ────────────────────────────────────────────────────

  static TextStyle get labelLarge => TextStyle(
        fontSize: SizeConfig.scaledFontSize(14),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => TextStyle(
        fontSize: SizeConfig.scaledFontSize(11),
        fontWeight: FontWeight.w400,
        color: Colors.grey[600],
      );
}
