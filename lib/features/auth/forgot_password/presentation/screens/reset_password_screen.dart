import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_provider.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_state.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/widgets/forgot_password_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 2 of the OTP reset flow: the admin enters the 6-digit code and a new
/// password. On success every old session is gone and they are routed to login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _done = false;
  String? _localOtpError;
  String? _localPasswordError;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;

    var valid = true;
    if (otp.length != 6) {
      _localOtpError = 'Enter the 6-digit code';
      valid = false;
    }
    if (password.length < 6) {
      _localPasswordError = 'Password must be at least 6 characters';
      valid = false;
    }
    setState(() {});
    if (!valid) return;

    final ok = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .resetPassword(otp: otp, newPassword: password);
    if (ok && mounted) {
      setState(() => _done = true);
    }
  }

  void _onResend() {
    setState(() {
      _localOtpError = null;
    });
    ref.read(forgotPasswordNotifierProvider.notifier).resendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordNotifierProvider);

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
                  child: _done
                      ? _SuccessView()
                      : _buildForm(state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(ForgotPasswordState state) {
    final otpError = _localOtpError ?? state.otpError;
    final passwordError = _localPasswordError ?? state.passwordError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.scale(4)),
        GlassBackButton(onTap: () => context.pop()),
        SizedBox(height: SizeConfig.scale(24)),

        const FpBadge(
          icon: Icons.sms_outlined,
          label: 'VERIFY CODE',
        ),
        SizedBox(height: SizeConfig.scale(14)),
        Text(
          'Enter Reset Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeConfig.scaledFontSize(28),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        SizedBox(height: SizeConfig.scale(8)),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: SizeConfig.scaledFontSize(13),
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text: 'We sent a 6-digit code to ',
              ),
              TextSpan(
                text: state.phoneNumber.isEmpty ? 'your phone' : state.phoneNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '. It expires in 10 minutes.'),
            ],
          ),
        ),

        SizedBox(height: SizeConfig.scale(28)),

        FpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(13),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: SizeConfig.scale(10)),
              FpPillField(
                controller: _otpController,
                icon: Icons.pin_outlined,
                hint: '••••••',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                letterSpacing: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                errorText: otpError,
                onChanged: (_) {
                  if (_localOtpError != null) {
                    setState(() => _localOtpError = null);
                  }
                },
              ),

              SizedBox(height: SizeConfig.scale(18)),

              Text(
                'New Password',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(13),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: SizeConfig.scale(10)),
              FpPillField(
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                hint: 'At least 6 characters',
                obscureText: _hidePassword,
                errorText: passwordError,
                onChanged: (_) {
                  if (_localPasswordError != null) {
                    setState(() => _localPasswordError = null);
                  }
                },
                trailing: GestureDetector(
                  onTap: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  child: Container(
                    width: SizeConfig.scale(36),
                    height: SizeConfig.scale(36),
                    alignment: Alignment.center,
                    child: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: SizeConfig.scale(18),
                    ),
                  ),
                ),
              ),

              if (state.errorMessage != null)
                FpInlineMessage(
                  message: state.errorMessage!,
                  warning: state.rateLimited,
                ),

              SizedBox(height: SizeConfig.scale(20)),

              FpPrimaryButton(
                label: 'Reset Password',
                isLoading: state.isLoading,
                onPressed: _onSubmit,
              ),

              SizedBox(height: SizeConfig.scale(14)),

              Center(child: _ResendRow(
                cooldown: state.resendCooldown,
                enabled: state.canResend && !state.isLoading,
                onResend: _onResend,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Didn't get it? Resend OTP" with the 60-second cooldown countdown.
class _ResendRow extends StatelessWidget {
  final int cooldown;
  final bool enabled;
  final VoidCallback onResend;
  const _ResendRow({
    required this.cooldown,
    required this.enabled,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Didn't receive it? ",
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(12),
            color: Colors.grey.shade500,
          ),
        ),
        if (enabled)
          GestureDetector(
            onTap: onResend,
            child: Text(
              'Resend OTP',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(12),
                color: kFpPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            'Resend in ${cooldown}s',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Confirmation shown after a successful reset, routing back to login.
class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: SizeConfig.scale(40)),
        Container(
          width: SizeConfig.scale(96),
          height: SizeConfig.scale(96),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: SizeConfig.scale(52),
          ),
        ),
        SizedBox(height: SizeConfig.scale(24)),
        Text(
          'Password Reset',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeConfig.scaledFontSize(26),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: SizeConfig.scale(10)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
          child: Text(
            'Your password has been changed and all previous sessions were '
            'signed out. Please log in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: SizeConfig.scaledFontSize(13),
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.scale(32)),
        FpPrimaryButton(
          label: 'Go to Login',
          isLoading: false,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
