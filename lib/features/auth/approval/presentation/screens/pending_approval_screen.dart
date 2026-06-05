import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const _kDark = AppColors.green;
const _kPrimary = AppColors.green;
const _kMid = AppColors.gradientStart;
const _kLight = AppColors.gradientEnd;

/// Shown to a signed-in user whose company is still awaiting admin approval.
///
/// The user is fully authenticated (has tokens) but gated out of the app shell
/// by the router. From here they can re-check their status — the moment an
/// admin approves them, the next check flips the router to the dashboard.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    if (_checking) return;
    setState(() => _checking = true);
    await ref.read(loginNotifierProvider.notifier).refreshApprovalStatus();
    if (!mounted) return;
    setState(() => _checking = false);

    // If the status flipped to approved/rejected the router has already
    // redirected; only surface a message when we are genuinely still pending.
    final after = ref.read(loginNotifierProvider);
    final stillPending = after is LoginSuccess &&
        (after.approvalStatus == ApprovalStatus.pendingApproval ||
            after.approvalStatus == ApprovalStatus.unknown);
    if (!stillPending) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your account is still under review.'),
        backgroundColor: _kMid,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() =>
      ref.read(loginNotifierProvider.notifier).logout();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
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
                      children: [
                        // ── Status badge ───────────────────────────────────────
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
                            Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: SizeConfig.scale(54),
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(28)),

                        Text(
                          'Account Under Review',
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
                          'Your account has been registered successfully and is '
                          'awaiting administrator approval. You will be able to '
                          'sign in as soon as it is activated.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.scaledFontSize(14),
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(32)),

                        // ── Check again ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checking ? null : _checkAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _kPrimary.withValues(
                                alpha: 0.5,
                              ),
                              disabledForegroundColor: Colors.white,
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
                            child: _checking
                                ? SizedBox(
                                    height: SizeConfig.scale(20),
                                    width: SizeConfig.scale(20),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Check Approval Status',
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(15),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.scale(12)),

                        // ── Logout ─────────────────────────────────────────────
                        TextButton(
                          onPressed: _checking ? null : _logout,
                          child: Text(
                            'Sign out',
                            style: TextStyle(
                              fontSize: SizeConfig.scaledFontSize(14),
                              fontWeight: FontWeight.w600,
                              color: _kMid,
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
