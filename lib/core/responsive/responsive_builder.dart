import 'package:flutter/material.dart';
import 'size_config.dart';

/// A reusable widget that initializes [SizeConfig] and provides responsive
/// layout information to its child builder.
///
/// Wrap any screen or complex widget with [ResponsiveBuilder] to get access
/// to the current [ScreenType], [Orientation], and [BoxConstraints].
///
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenType, orientation, constraints) {
///     return screenType == ScreenType.large
///         ? _buildTabletLayout()
///         : _buildPhoneLayout();
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    ScreenType screenType,
    Orientation orientation,
    BoxConstraints constraints,
  ) builder;

  @override
  Widget build(BuildContext context) {
    // Initialize SizeConfig on every rebuild so it stays in sync with
    // orientation changes and dynamic resizing.
    SizeConfig.init(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return builder(
              context,
              SizeConfig.screenType,
              orientation,
              constraints,
            );
          },
        );
      },
    );
  }
}
