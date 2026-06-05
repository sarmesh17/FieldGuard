import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class DotIndicator extends StatefulWidget {
  final int dotCount;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const DotIndicator({
    super.key,
    this.dotCount = 3,
    this.activeColor = Colors.white,
    this.inactiveColor = AppColors.white17,
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  @override
  State<DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: widget.dotCount.toDouble())
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.dotCount,
            (index) {
              final distance = (_animation.value - index).abs();
              final opacity = (1 - (distance / widget.dotCount)).clamp(0.3, 1.0);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.activeColor.withValues(alpha: opacity),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
