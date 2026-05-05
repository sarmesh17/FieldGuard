import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/responsive.dart';
import 'onboarding_design.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        final provider = context.watch<OnboardingProvider>();
        final pages = provider.pages;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F1),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  /// Top: Skip button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: navigate to login/home
                        },
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

                  /// Page View — takes available space
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        provider.updateIndex(index);
                      },
                      itemBuilder: (context, index) {
                        return OnboardingDesign(
                          image: pages[index]['image'] ?? "",
                          title: pages[index]['title'] ?? "",
                          subTitle: pages[index]['subtitle'] ?? "",
                        );
                      },
                    ),
                  ),

                  /// Bottom section
                  _buildBottomSection(context, provider, pages),
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
    OnboardingProvider provider,
    List<Map<String, String>> pages,
  ) {
    final isLastPage = provider.currentIndex == pages.length - 1;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => _dot(index == provider.currentIndex),
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(3)),

          /// Next / Get Started Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isLastPage) {
                  // TODO: navigate to login/home
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
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                ),
                elevation: 4,
              ),
              child: Text(
                isLastPage ? 'Get Started' : 'Next',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(2.5)),

          /// Back / Login link
          GestureDetector(
            onTap: () {
              if (!isLastPage && provider.currentIndex > 0) {
                _controller.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: isLastPage
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
        color: active ? const Color(0xFF1F5E3B) : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(SizeConfig.scale(10)),
      ),
    );
  }
}
