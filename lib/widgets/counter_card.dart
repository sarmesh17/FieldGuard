import 'package:flutter/material.dart';
import '../core/responsive/responsive.dart';

/// A responsive card displaying the counter value.
///
/// Adapts its internal sizing and typography to the current screen size
/// without using any fixed pixel dimensions.
class CounterCard extends StatelessWidget {
  const CounterCard({super.key, required this.counter});

  final int counter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      widthFactor: SizeConfig.screenType == ScreenType.large ? 0.7 : 1.0,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'You have pushed the button this many times:',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '$counter',
                style: AppTextStyles.displayLarge.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
