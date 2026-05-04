import 'package:fieldguard/presentation/screens/splash_screen/moving_indicator/moving_indicator.dart';
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
            colors: [Color(0xFF2E6F4F), Color(0xFF5FBF8F)],
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
                      fontFamily: 'Serif',
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
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 4),

              // Bottom Indicators
              DotIndicator(),

              SizedBox(height: size.height * 0.03),

              const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white, fontSize: 12),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
    );
  }
}
