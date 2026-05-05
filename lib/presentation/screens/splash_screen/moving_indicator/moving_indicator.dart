import 'package:flutter/material.dart';

class DotIndicator extends StatefulWidget {
  const DotIndicator();

  @override
  State<DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<DotIndicator> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // loop animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        currentIndex = (currentIndex + 1) % 3;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: currentIndex == index ? 12 : 8,
          height: currentIndex == index ? 12 : 8,
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