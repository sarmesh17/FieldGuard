import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _kDark = AppColors.green;
const _kMid = AppColors.gradientStart;
const _kDanger = AppColors.red;
const _kDangerSoft = AppColors.red6;

/// Shown when the company's registration was rejected by an administrator.
///
/// Terminal state for this account — there is no "retry" from inside the app.
/// The reason (if the admin provided one) is surfaced verbatim so the user
/// knows what to address before contacting support.
class AccountRejectedScreen extends ConsumerWidget {
  const AccountRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(loginNotifierProvider);
    final reason = auth is LoginSuccess ? auth.rejectionReason : null;

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.scale(28),
                  vertical: SizeConfig.scale(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Status badge ───────────────────────────────────────────
                    Container(
                      width: SizeConfig.scale(110),
                      height: SizeConfig.scale(110),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kDangerSoft,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        color: _kDanger,
                        size: SizeConfig.scale(56),
                      ),
                    ),

                    SizedBox(height: SizeConfig.scale(28)),

                    Text(
                      'Registration Not Approved',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(22),
                        fontWeight: FontWeight.w800,
                        color: _kDark,
                        letterSpacing: 0.2,
                      ),
                    ),

                    SizedBox(height: SizeConfig.scale(12)),

                    Text(
                      'Your company registration has been reviewed and could '
                      'not be approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(14),
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    if (reason != null && reason.trim().isNotEmpty) ...[
                      SizedBox(height: SizeConfig.scale(20)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(SizeConfig.scale(16)),
                        decoration: BoxDecoration(
                          color: _kDangerSoft,
                          borderRadius: BorderRadius.circular(
                            SizeConfig.scale(14),
                          ),
                          border: Border.all(
                            color: _kDanger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason from administrator',
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(12),
                                fontWeight: FontWeight.w700,
                                color: _kDanger,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: SizeConfig.scale(8)),
                            Text(
                              reason,
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(14),
                                height: 1.45,
                                color: _kDark.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: SizeConfig.scale(28)),

                    Text(
                      'If you believe this is a mistake, please contact support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: Colors.grey.shade600,
                      ),
                    ),

                    SizedBox(height: SizeConfig.scale(24)),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            ref.read(loginNotifierProvider.notifier).logout(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kMid,
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
                          'Sign out',
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(15),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
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
