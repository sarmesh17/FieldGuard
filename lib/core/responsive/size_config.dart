import 'package:flutter/material.dart';

/// Defines screen size breakpoints for responsive design.
enum ScreenType { small, medium, large }

/// Centralized responsive sizing configuration.
///
/// Initialize once at the top of your widget tree (or in each screen's build)
/// using [SizeConfig.init]. Then access scaled dimensions anywhere via the
/// static getters and helper methods.
class SizeConfig {
  // Private constructor — use static API only.
  SizeConfig._();

  // ─── Raw screen metrics ───────────────────────────────────────────────────

  static late double screenWidth;
  static late double screenHeight;
  static late double textScaleFactor;
  static late Orientation orientation;
  static late ScreenType screenType;

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Call this in your top-level build method or via [ResponsiveBuilder].
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    textScaleFactor = mediaQuery.textScaler.scale(1.0);
    orientation = mediaQuery.orientation;
    screenType = _resolveScreenType(screenWidth);
  }

  static ScreenType _resolveScreenType(double width) {
    if (width < 360) return ScreenType.small;
    if (width <= 600) return ScreenType.medium;
    return ScreenType.large;
  }

  // ─── Percentage-based sizing helpers ──────────────────────────────────────

  /// Returns a width value as a percentage of screen width.
  /// Example: `SizeConfig.widthPercent(90)` → 90% of screen width.
  static double widthPercent(double percent) => screenWidth * percent / 100;

  /// Returns a height value as a percentage of screen height.
  static double heightPercent(double percent) => screenHeight * percent / 100;

  // ─── Scalable spacing & font sizes ────────────────────────────────────────

  /// Scales a base value relative to a 375-wide reference design.
  /// Keeps proportions consistent across devices.
  static double scale(double value) => value * (screenWidth / 375);

  /// Scalable font size that respects system text scaling.
  static double scaledFontSize(double baseFontSize) {
    final scaled = scale(baseFontSize);
    // Clamp to avoid excessively large text on tablets or tiny text on small
    // phones while still respecting user accessibility preferences.
    return scaled * textScaleFactor.clamp(0.8, 1.3);
  }

  // ─── Short-screen aware scaling ───────────────────────────────────────────

  /// Reference design height (matches the 375-wide reference width).
  static const double _refHeight = 812;

  /// Scales a base value by the *smaller* of the width and height ratios.
  ///
  /// Unlike [scale] (width-only), this shrinks values on short devices so
  /// fixed-height content (logos, paddings, buttons) doesn't overflow or
  /// overlap vertically. Use for vertical dimensions on height-constrained
  /// layouts; [scale] remains the default for horizontal/general sizing.
  static double vScale(double value) {
    final widthRatio = screenWidth / 375;
    final heightRatio = screenHeight / _refHeight;
    final factor = widthRatio < heightRatio ? widthRatio : heightRatio;
    return value * factor;
  }

  /// Like [scaledFontSize] but uses the shorter screen side (via [vScale]) so
  /// text doesn't balloon in landscape. Still respects system text scaling.
  static double vScaledFontSize(double baseFontSize) {
    final scaled = vScale(baseFontSize);
    return scaled * textScaleFactor.clamp(0.8, 1.3);
  }
}
