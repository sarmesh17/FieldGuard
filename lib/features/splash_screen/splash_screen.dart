import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/widgets/moving_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/responsive.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Splash screen — shown on app launch.
/// Checks authentication state and navigates accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Logo pops in first (elastic), then the text fades + slides up.
    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Wait minimum 2 seconds for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check auth state
    final authState = ref.read(loginNotifierProvider);

    if (authState is LoginSuccess) {
      // User is already logged in, go to dashboard
      context.go(AppRoutes.dashboard);
    } else {
      // User not logged in, go to login
      context.go(AppRoutes.login);
    }
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.green,
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
              ),
            ),
            child: Stack(
              // Force the content layer to fill the screen so it stays
              // centred — without this the non-positioned child shrinks and
              // hugs the left edge.
              fit: StackFit.expand,
              children: [
                // Soft decorative glow blobs for depth.
                Positioned(
                  top: -SizeConfig.scale(80),
                  right: -SizeConfig.scale(60),
                  child: _blob(SizeConfig.scale(220), 0.10),
                ),
                Positioned(
                  bottom: -SizeConfig.scale(70),
                  left: -SizeConfig.scale(70),
                  child: _blob(SizeConfig.scale(200), 0.08),
                ),
                SafeArea(
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _blob(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(scale: _logoScale, child: const _Logo()),
        SizedBox(height: SizeConfig.heightPercent(3)),
        FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'FieldGuard HQ',
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
                  'ADMIN  /  MANAGER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: SizeConfig.scaledFontSize(13),
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return FadeTransition(
      opacity: _fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DotIndicator(),
          SizedBox(height: SizeConfig.heightPercent(3)),
          Text(
            'v1.0.0',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: SizeConfig.scaledFontSize(11),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2.5)),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final logoSize = SizeConfig.scale(78);

    return Container(
      width: logoSize * 1.55,
      height: logoSize * 1.55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(logoSize * 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.shield_outlined,
          color: Colors.white,
          size: logoSize * 0.55,
        ),
      ),
    );
  }
}
