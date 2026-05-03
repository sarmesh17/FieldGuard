
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E6F4F),
              Color(0xFF5FBF8F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Center Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(),

                  SizedBox(height: size.height * 0.04),

                  const Text(
                    'FieldGuard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: size.height * 0.015),

                  Container(
                    width: 60,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.5),
                  ),

                  SizedBox(height: size.height * 0.02),

                  const Text(
                    'MANAGER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 4),

              // Bottom Indicators
              const _DotIndicator(),

              SizedBox(height: size.height * 0.03),

              const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),

              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.shield,
        color: Color(0xFF2E6F4F),
        size: 40,
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index == 1 ? 0.9 : 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}