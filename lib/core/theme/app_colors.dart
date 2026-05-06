import 'package:flutter/material.dart';

/// Centralized color palette for FieldGuard.
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1F5E3B);
  static const Color primaryLight = Color(0xFF2F6F4E);
  static const Color primaryDark = Color(0xFF1A4F32);

  // ─── Gradient ─────────────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF2E6F4F);
  static const Color gradientEnd = Color(0xFF5FBF8F);

  // ─── Background ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F4F1);
  static const Color backgroundAlt = Color(0xFFEDEEEA);
  static const Color loginBackground = Color(0xFFDFEEE4);

  // ─── Surface ──────────────────────────────────────────────────────────────
  static const Color surface = Colors.white;

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  // ─── Misc ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFB00020);
}
