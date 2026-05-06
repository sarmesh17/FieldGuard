import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/moving_indicator.dart';

/// Splash screen — shown on app launch.
/// Auto-navigates to onboarding after a short delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
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
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: innerConstraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(height: SizeConfig.heightPercent(5)),
                          _buildCenterContent(),
                          _buildBottomSection(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(),
        SizedBox(height: SizeConfig.heightPercent(3)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'FieldGuard',
            style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.scaledFontSize(30),
              fontFamily: 'Serif',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(1.5)),
        Container(
          width: SizeConfig.widthPercent(15),
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        SizedBox(height: SizeConfig.heightPercent(2)),
        Text(
          'MANAGER',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: SizeConfig.scaledFontSize(14),
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DotIndicator(),
        SizedBox(height: SizeConfig.heightPercent(3)),
        Text(
          'v1.0.0',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeConfig.scaledFontSize(11),
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(2.5)),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final logoSize = SizeConfig.scale(75);

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(SizeConfig.scale(18)),
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: logoSize * 0.55,
      ),
    );
  }
}
