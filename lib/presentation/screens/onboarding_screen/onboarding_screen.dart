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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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

              SizedBox(height: size.height * 0.02),
              SizedBox(
                height: size.height * 0.56, // adjust as per design
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
              SizedBox(height: size.height * 0.1 * 0.5),

              /// Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _dot(index == provider.currentIndex),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              ///
              InkWell(
                onTap: () {
                  if (provider.currentIndex == pages.length - 1) {
                  } else {
                    _controller.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F5E3B),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              /// Back
              InkWell(
                onTap: () {},
                child: provider.currentIndex == pages.length - 1
                    ? RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black54, fontSize: 18),
                          children: [
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
                    : Text('Back', style: TextStyle(fontSize: 20)),
              ),

              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 30 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1F5E3B) : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
