import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../notifiers/onboarding_notifier.dart';
import 'onboarding_design.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F1),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  /// Skip button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: const Color(0xFF1F5E3B),
                            fontSize: SizeConfig.scaledFontSize(15),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.heightPercent(1.5)),

                  /// Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: state.pages.length,
                      onPageChanged: notifier.updateIndex,
                      itemBuilder: (context, index) {
                        final page = state.pages[index];
                        return OnboardingDesign(
                          imageUrl: page.imageUrl,
                          title: page.title,
                          subTitle: page.subtitle,
                        );
                      },
                    ),
                  ),

                  /// Bottom controls
                  _buildBottomSection(context, state, notifier),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              state.pages.length,
              (index) => _dot(index == state.currentIndex),
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(3)),

          /// Next / Get Started
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (state.isLastPage) {
                  context.go(AppRoutes.login);
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5E3B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: SizeConfig.scale(16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                ),
                elevation: 4,
              ),
              child: Text(
                state.isLastPage ? 'Get Started' : 'Next',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(2.5)),

          /// Back / Already have account
          GestureDetector(
            onTap: () {
              if (state.isLastPage) {
                context.go(AppRoutes.login);
              } else if (state.currentIndex > 0) {
                _controller.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: state.isLastPage
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: SizeConfig.scaledFontSize(14),
                        ),
                        children: const [
                          TextSpan(text: 'Already have an account?  '),
                          TextSpan(
                            text: 'Log In',
                            style: TextStyle(
                              color: Color(0xFF1F5E3B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    'Back',
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(14),
                      color: Colors.black54,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.scale(5)),
      width: active ? SizeConfig.scale(22) : SizeConfig.scale(8),
      height: SizeConfig.scale(8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1F5E3B)
            : Colors.grey.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
      ),
    );
  }
}
