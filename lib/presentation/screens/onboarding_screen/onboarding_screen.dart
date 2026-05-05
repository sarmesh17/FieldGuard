import 'package:fieldguard/presentation/screens/onboarding_screen/onboarding_design.dart';
import 'package:fieldguard/presentation/screens/onboarding_screen/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<OnboardingProvider>();
    final pages = provider.pages;

    // 🔹 responsive text
    double buttonTextSize = (size.width * 0.045).clamp(16, 20);
    double backTextSize = (size.width * 0.04).clamp(14, 18);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 243, 239),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 🔥 key fix
            children: [
              /// 🔹 TOP SECTION
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: size.height * 0.01),
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Color(0xFF1F5E3B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  /// 🔹 PAGE VIEW
                  SizedBox(
                    height: size.height * 0.60,
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
                ],
              ),

              /// 🔹 BOTTOM SECTION
              Column(
                mainAxisAlignment: MainAxisAlignment.start,

                children: [
                  /// Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => _dot(index == provider.currentIndex),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),

                  /// Button
                  InkWell(
                    onTap: () {
                      if (provider.currentIndex == pages.length - 1) {
                        // TODO: navigate
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.065, // 🔥 responsive height
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5E3B),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          provider.currentIndex == pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.025),

                  /// Back / Login
                  InkWell(
                    onTap: () {},
                    child: provider.currentIndex == pages.length - 1
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: backTextSize,
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
                          )
                        : Text(
                            'Back',
                            style: TextStyle(fontSize: backTextSize),
                          ),
                  ),

                  SizedBox(height: size.height * 0.04),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 22 : 8, // 🔥 balanced (30 was too big)
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1F5E3B) : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
