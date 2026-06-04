import 'package:flutter/material.dart';

/// Centralized color palette for FieldGuard.
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1F5E3B);
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

  // ─── Generated palette (centralized from UI literals) ──────────────────────

  // green
  static const Color green = Color(0xFF0E5A3B); // ×192
  static const Color green2 = Color(0xFF005C33); // ×17
  static const Color green3 = Color(0xFF1D7A51); // ×13
  static const Color green4 = Color(0xFFDDF5E0); // ×11
  static const Color green5 = Color(0xFF22C55E); // ×8
  static const Color green6 = Color(0xFFF0FDF4); // ×14
  static const Color green7 = Color(0xFF00874C); // ×7
  static const Color green8 = Color(0xFF072A1C); // ×7
  static const Color green9 = Color(0xFF16A34A); // ×7
  static const Color green10 = Color(0xFF1A4731); // ×7
  static const Color green11 = Color(0xFFD1FADF); // ×7
  static const Color green12 = Color(0xFF165C3D); // ×6
  static const Color green13 = Color(0xFF1F6B46); // ×5
  static const Color green14 = Color(0xFFD8E7DE); // ×4
  static const Color green15 = Color(0xFFDCF5E4); // ×3
  static const Color green16 = Color(0xFF003D22); // ×2
  static const Color green17 = Color(0xFF0B4A30); // ×2
  static const Color green18 = Color(0xFF0B6A3F); // ×2
  static const Color green19 = Color(0xFF5BC88B); // ×2
  static const Color green20 = Color(0x330E5A3B); // ×1
  static const Color green21 = Color(0xFF004D2B); // ×1
  static const Color green22 = Color(0xFF045C38); // ×1
  static const Color green23 = Color(0xFF0B4E32); // ×1
  static const Color green24 = Color(0xFF2E7D32); // ×1
  static const Color green25 = Color(0xFF2E7D52); // ×1
  static const Color green26 = Color(0xFF2E8B57); // ×1
  static const Color green27 = Color(0xFF3BA66B); // ×1
  static const Color green28 = Color(0xFF4CB67A); // ×1
  static const Color green29 = Color(0xFF6EE7B7); // ×1
  static const Color green30 = Color(0xFFD0EDE0); // ×1
  static const Color green31 = Color(0xFFE8F5EE); // ×2

  // teal
  static const Color teal = Color(0xFF163B45); // ×1

  // blue
  static const Color blue = Color(0xFF6558FF); // ×42
  static const Color blue2 = Color(0xFF374151); // ×14
  static const Color blue3 = Color(0xFF3B82F6); // ×9
  static const Color blue6 = Color(0xFF1F2937); // ×2
  static const Color blue7 = Color(0xFFEEE9FF); // ×2
  static const Color blue8 = Color(0xFFEFF6FF); // ×2
  static const Color blue9 = Color(0xFF2980B9); // ×1
  static const Color blue10 = Color(0xFF5751C9); // ×1
  static const Color blue11 = Color(0xFF5A56E8); // ×1
  static const Color blue12 = Color(0xFFCBD5E1); // ×1
  static const Color blue13 = Color(0xFFD0D5DD); // ×2
  static const Color blue14 = Color(0xFFD7DDE4); // ×1

  // purple
  static const Color purple = Color(0xFF8B3DFF); // ×4
  static const Color purple2 = Color(0xFF9B4EFF); // ×2

  // pink
  static const Color pink = Color(0xFFD946EF); // ×1

  // red
  static const Color red = Color(0xFFC0392B); // ×15
  static const Color red2 = Color(0xFFFF3B3B); // ×13
  static const Color red3 = Color(0xFFE53935); // ×12
  static const Color red4 = Color(0xFFEF4444); // ×11
  static const Color red5 = Color(0xFFFF3347); // ×11
  static const Color red6 = Color(0xFFFEE2E2); // ×8
  static const Color red7 = Color(0xFFFCA5A5); // ×5
  static const Color red8 = Color(0xFFFFE3E6); // ×6
  static const Color red9 = Color(0xFF7A1F1F); // ×4
  static const Color red10 = Color(0xFFB91C1C); // ×4
  static const Color red11 = Color(0xFFB93A3A); // ×2
  static const Color red12 = Color(0xFFFF3B30); // ×2
  static const Color red13 = Color(0xFF991B1B); // ×1
  static const Color red14 = Color(0xFFB0413E); // ×1
  static const Color red15 = Color(0xFFC62828); // ×1
  static const Color red16 = Color(0xFFDC2626); // ×1
  static const Color red17 = Color(0xFFE7B1B1); // ×1
  static const Color red18 = Color(0xFFFF6B6B); // ×1
  static const Color red19 = Color(0xFFFFCDD2); // ×1

  // brown
  static const Color brown = Color(0xFFB7791F); // ×6
  static const Color brown2 = Color(0xFF92722A); // ×1
  static const Color brown3 = Color(0xFFA4510B); // ×1
  static const Color brown4 = Color(0xFFB45309); // ×1
  static const Color brown5 = Color(0xFFB96A11); // ×1

  // orange
  static const Color orange = Color(0xFFE8E1D7); // ×9
  static const Color orange2 = Color(0xFFF59E0B); // ×6
  static const Color orange3 = Color(0xFFEA8C2A); // ×4
  static const Color orange4 = Color(0xFFF2A14A); // ×2
  static const Color orange5 = Color(0xFFFF8F00); // ×2
  static const Color orange6 = Color(0xFFF97316); // ×1
  static const Color orange7 = Color(0xFFFFE0A3); // ×1
  static const Color orange8 = Color(0xFFFFF7E6); // ×1
  static const Color orange9 = Color(0xFFFFF7ED); // ×1

  // yellow
  static const Color yellow = Color(0xFFFCD34D); // ×1
  static const Color yellow2 = Color(0xFFFEF3C7); // ×1
  static const Color yellow3 = Color(0xFFFFE082); // ×1
  static const Color yellow4 = Color(0xFFFFF8E1); // ×1

  // grey
  static const Color grey = Color(0xFF667085); // ×113
  static const Color grey2 = Color(0xFF9CA3AF); // ×47
  static const Color grey3 = Color(0xFFE8E3DD); // ×43
  static const Color grey4 = Color(0xFFE5E7EB); // ×35
  static const Color grey5 = Color(0xFF6B7280); // ×33
  static const Color grey7 = Color(0xFFE0E4EA); // ×17
  static const Color grey8 = Color(0xFF8A94A6); // ×13
  static const Color grey9 = Color(0xFFB0B7C3); // ×9
  static const Color grey10 = Color(0xFF5A6472); // ×7
  static const Color grey11 = Color(0xFFAAB2BD); // ×5
  static const Color grey12 = Color(0xFFE8EDEA); // ×5
  static const Color grey13 = Color(0xFF2D2D2D); // ×4
  static const Color grey14 = Color(0xFFDDD8D1); // ×3
  static const Color grey15 = Color(0xFFE4EDE8); // ×3
  static const Color grey16 = Color(0xFF424242); // ×3
  static const Color grey17 = Color(0xFF7A8190); // ×2
  static const Color grey18 = Color(0xFFBDBDBD); // ×2
  static const Color grey19 = Color(0xFF1E2A20); // ×1
  static const Color grey21 = Color(0xFF3B3B3B); // ×1
  static const Color grey23 = Color(0xFF4B4B4B); // ×1
  static const Color grey24 = Color(0xFF4B5563); // ×1
  static const Color grey25 = Color(0xFF6C7485); // ×1
  static const Color grey26 = Color(0xFF8A7178); // ×1
  static const Color grey27 = Color(0xFF98A2B3); // ×1
  static const Color grey28 = Color(0xFF9AA09B); // ×1
  static const Color grey30 = Color(0xFFD9D9D9); // ×1
  static const Color grey31 = Color(0xFFDCE1E7); // ×1
  static const Color grey32 = Color(0xFFDFDDD8); // ×2
  static const Color grey34 = Color(0xFFE5E5E5); // ×1

  // ink
  static const Color ink = Color(0xFF111827); // ×28
  static const Color ink2 = Color(0xFF0D1B2A); // ×16

  // white
  static const Color white = Color(0xFFF8FAF9); // ×29
  static const Color white2 = Color(0xFFF5F6FA); // ×35
  static const Color white4 = Color(0xFFF0F2F5); // ×17
  static const Color white9 = Color(0xFFE9EDF1); // ×5
  static const Color white10 = Color(0xFFFEF2F2); // ×4
  static const Color white16 = Color(0xFFFFFFFF); // ×2
  static const Color white17 = Color(0x80FFFFFF); // ×1
  static const Color white22 = Color(0xFFF0ECE6); // ×1
  static const Color white28 = Color(0xFFFDF4FF); // ×1

  // black
  static const Color black = Color(0xFF111111); // ×51
  static const Color black2 = Color(0x0A000000); // ×1
}
