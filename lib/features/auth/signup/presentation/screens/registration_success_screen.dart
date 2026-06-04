import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const _kDark = AppColors.green10;
const _kPrimary = AppColors.green12;
const _kMid = AppColors.gradientStart;
const _kLight = AppColors.gradientEnd;

/// Shown after a company account is successfully registered.
///
/// A new account is **not** active immediately — a super admin must approve it
/// before the user can sign in. This screen makes that explicit so the user
/// does not try (and fail) to log in right away.
class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ── Soft gradient backdrop ──────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.green6, Colors.white],
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.scale(28),
                      vertical: SizeConfig.scale(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Success badge ──────────────────────────────────────
                        Container(
                          width: SizeConfig.scale(110),
                          height: SizeConfig.scale(110),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_kPrimary, _kLight],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withValues(alpha: 0.30),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: SizeConfig.scale(60),
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(28)),

                        // ── Heading ────────────────────────────────────────────
                        Text(
                          'Thank You for Registering',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(22),
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                            letterSpacing: 0.2,
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(12)),

                        // ── Body copy ──────────────────────────────────────────
                        Text(
                          'Your account has been created successfully. '
                          'For security, every new account is reviewed before '
                          'activation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(14),
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(20)),

                        // ── Approval notice ────────────────────────────────────
                        Container(
                          padding: EdgeInsets.all(SizeConfig.scale(16)),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(
                              SizeConfig.scale(14),
                            ),
                            border: Border.all(
                              color: _kPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: _kMid,
                                size: SizeConfig.scale(22),
                              ),
                              SizedBox(width: SizeConfig.scale(12)),
                              Expanded(
                                child: Text(
                                  'You can sign in only after an administrator '
                                  'approves your account. We will notify you '
                                  'once it is activated.',
                                  style: TextStyle(
                                    fontSize: SizeConfig.scaledFontSize(13),
                                    height: 1.45,
                                    color: _kDark.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(32)),

                        // ── Login button ───────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                SizeConfig.scale(14),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withValues(alpha: 0.30),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => context.go(AppRoutes.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.scale(16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SizeConfig.scale(14),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Go to Login',
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(15),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
