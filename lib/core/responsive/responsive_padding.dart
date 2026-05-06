import 'package:flutter/material.dart';
import 'size_config.dart';

/// Centralized, scalable spacing and padding values.
///
/// All values are derived from [SizeConfig.scale] so they adapt
/// proportionally across screen sizes.
class AppSpacing {
  AppSpacing._();

  // ─── Base spacing scale ───────────────────────────────────────────────────

  static double get xs => SizeConfig.scale(4);
  static double get sm => SizeConfig.scale(8);
  static double get md => SizeConfig.scale(16);
  static double get lg => SizeConfig.scale(24);
  static double get xl => SizeConfig.scale(32);
  static double get xxl => SizeConfig.scale(48);

  // ─── Common padding presets ───────────────────────────────────────────────

  /// Standard screen-level horizontal padding.
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: _screenHorizontal,
        vertical: md,
      );

  /// Card-level internal padding.
  static EdgeInsets get cardPadding => EdgeInsets.all(md);

  /// Section spacing (vertical gap between major sections).
  static SizedBox get sectionGap => SizedBox(height: lg);

  /// Item spacing (vertical gap between list items or form fields).
  static SizedBox get itemGap => SizedBox(height: sm);

  // ─── Private helpers ──────────────────────────────────────────────────────

  static double get _screenHorizontal {
    switch (SizeConfig.screenType) {
      case ScreenType.small:
        return SizeConfig.scale(12);
      case ScreenType.medium:
        return SizeConfig.scale(16);
      case ScreenType.large:
        return SizeConfig.scale(24);
    }
  }
}
