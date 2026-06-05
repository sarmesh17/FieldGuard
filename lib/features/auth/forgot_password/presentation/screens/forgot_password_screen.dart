import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_provider.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/widgets/forgot_password_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of the OTP reset flow: the admin enters their phone number to receive
/// a reset code by SMS.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  String? _localPhoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _localPhoneError = 'Enter your 10-digit phone number');
      return;
    }
    setState(() => _localPhoneError = null);

    final ok = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .requestOtp(phone);
    if (ok && mounted) {
      context.push(AppRoutes.resetPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordNotifierProvider);
    final fieldError = _localPhoneError ?? state.phoneError;

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: BrandBackdrop(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 0 : AppSpacing.md,
                vertical: SizeConfig.scale(12),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 480 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfig.scale(4)),
                      GlassBackButton(onTap: () => context.pop()),
                      SizedBox(height: SizeConfig.scale(24)),

                      // ── Header ───────────────────────────────────────────
                      const FpBadge(
                        icon: Icons.lock_reset_rounded,
                        label: 'PASSWORD RESET',
                      ),
                      SizedBox(height: SizeConfig.scale(14)),
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.scaledFontSize(28),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: SizeConfig.scale(8)),
                      Text(
                        'Enter your registered phone number and we will send a '
                        'verification code by SMS.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: SizeConfig.scaledFontSize(13),
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: SizeConfig.scale(28)),

                      // ── Card ─────────────────────────────────────────────
                      FpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: SizeConfig.scaledFontSize(13),
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: SizeConfig.scale(10)),
                            FpPillField(
                              controller: _phoneController,
                              icon: Icons.phone_android_rounded,
                              hint: '9800000000',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              errorText: fieldError,
                              onChanged: (_) {
                                if (_localPhoneError != null) {
                                  setState(() => _localPhoneError = null);
                                }
                              },
                            ),

                            if (state.errorMessage != null)
                              FpInlineMessage(
                                message: state.errorMessage!,
                                warning: state.rateLimited,
                              ),

                            SizedBox(height: SizeConfig.scale(20)),

                            FpPrimaryButton(
                              label: 'Send OTP',
                              isLoading: state.isLoading,
                              onPressed: _onSubmit,
                            ),

                            SizedBox(height: SizeConfig.scale(12)),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: SizeConfig.scale(14),
                                  color: Colors.grey.shade500,
                                ),
                                SizedBox(width: SizeConfig.scale(6)),
                                Expanded(
                                  child: Text(
                                    'Password reset is available for company '
                                    'admin accounts only.',
                                    style: TextStyle(
                                      fontSize: SizeConfig.scaledFontSize(11),
                                      color: Colors.grey.shade500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
