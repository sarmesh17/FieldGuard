import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive.dart';

class DotIndicator extends StatefulWidget {
  const DotIndicator({super.key});

  @override
  State<DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<DotIndicator> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return false;
      setState(() {
        currentIndex = (currentIndex + 1) % 3;
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
          width: currentIndex == index ? activeDotSize : dotSize,
          height: currentIndex == index ? activeDotSize : dotSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              currentIndex == index ? 1 : 0.4,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
