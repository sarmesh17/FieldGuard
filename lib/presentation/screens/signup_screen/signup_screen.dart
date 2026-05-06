import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';

/// Placeholder sign-up screen.
/// TODO: Implement full sign-up flow with form validation and API integration.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sign Up'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: SizeConfig.scale(80),
                      color: Colors.grey,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(24),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign-up flow coming soon.',
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Go to Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
