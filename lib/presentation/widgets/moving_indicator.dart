import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';

/// Animated loading dot indicator used on the splash screen.
class DotIndicator extends StatefulWidget {
  const DotIndicator({super.key});

  @override
  State<DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<DotIndicator> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return false;
      setState(() {
        _currentIndex = (_currentIndex + 1) % 3;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = SizeConfig.scale(8);
    final activeDotSize = SizeConfig.scale(12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.scale(6)),
          width: _currentIndex == index ? activeDotSize : dotSize,
          height: _currentIndex == index ? activeDotSize : dotSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: _currentIndex == index ? 1.0 : 0.4,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
