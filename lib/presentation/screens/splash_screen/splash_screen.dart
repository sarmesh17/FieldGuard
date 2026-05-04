import 'package:fieldguard/presentation/screens/splash_screen/moving_indicator/moving_indicator.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔹 clamp for better scaling on very small/large devices
    double titleSize = (size.width * 0.08).clamp(26, 34);
    double subTitleSize = (size.width * 0.035).clamp(12, 16);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔥 key change
            children: [
              const SizedBox(), // top spacer

              /// 🔹 Center Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(),

                  SizedBox(height: size.height * 0.03),

                  Text(
                    'FieldGuard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontFamily: 'Serif',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: size.height * 0.015),

                  Container(
                    width: size.width * 0.15, // 🔥 responsive
                    height: 1.5,
                    color: Colors.white.withOpacity(0.5),
                  ),

                  SizedBox(height: size.height * 0.02),

                  Text(
                    'MANAGER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: subTitleSize,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                ],
              ),

              /// 🔹 Bottom Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DotIndicator(),

                  SizedBox(height: size.height * 0.030),

                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (size.width * 0.03).clamp(10, 12),
                    ),
                  ),

                  SizedBox(height: size.height * 0.025),
                ],
              ),
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
    final size = MediaQuery.of(context).size;

    double logoSize = (size.width * 0.18).clamp(60, 90);

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: logoSize * 0.55, // 🔥 proportional icon
      ),
    );
  }
}