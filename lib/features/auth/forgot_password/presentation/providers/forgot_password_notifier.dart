import 'dart:async';

import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/reset_password_messages.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/usecase/request_otp_usecase.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/usecase/reset_password_usecase.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_state.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Drives the two-screen OTP reset flow. Both screens share this single
/// notifier so the resend cooldown and the entered phone number persist across
/// the navigation between them.
class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final RequestOtpUsecase _requestOtp;
  final ResetPasswordUsecase _resetPassword;

  /// Backend enforces a 60s resend window; mirror it client-side so the button
  /// stays disabled until a fresh OTP can actually be sent.
  static const int _resendCooldownSeconds = 60;

  Timer? _timer;

  ForgotPasswordNotifier(this._requestOtp, this._resetPassword)
      : super(const ForgotPasswordState());

  /// Step 1 — request an OTP. Returns true when the request is accepted so the
  /// caller can advance to the OTP screen. Note: a true result does NOT confirm
  /// the number is registered (the backend hides that for security).
  Future<bool> requestOtp(String phoneNumber) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearFieldErrors: true,
      rateLimited: false,
    );

    final result = await _requestOtp(phoneNumber);
    switch (result) {
      case Success():
        state = ForgotPasswordState(phoneNumber: phoneNumber);
        _startCooldown();
        return true;
      case Failure(:final exception):
        _applyError(exception);
        return false;
    }
  }

  /// Re-request an OTP for the stored number. No-op while the cooldown is
  /// running or another call is in flight.
  Future<void> resendOtp() async {
    if (!state.canResend || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      rateLimited: false,
    );

    final result = await _requestOtp(state.phoneNumber);
    switch (result) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          clearFieldErrors: true,
        );
        _startCooldown();
      case Failure(:final exception):
        _applyError(exception);
    }
  }

  /// Step 2 — verify the OTP and set the new password. Returns true on success
  /// so the caller can show the confirmation and route to login.
  Future<bool> resetPassword({
    required String otp,
    required String newPassword,
  }) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearFieldErrors: true,
      rateLimited: false,
    );

    final result = await _resetPassword(
      phoneNumber: state.phoneNumber,
      otp: otp,
      newPassword: newPassword,
    );
    switch (result) {
      case Success():
        _timer?.cancel();
        state = state.copyWith(isLoading: false, resendCooldown: 0);
        return true;
      case Failure(:final exception):
        // Reset-specific friendly copy for the general (non-field) errors —
        // most importantly turning a raw 401 into "Incorrect or expired code…".
        _applyError(exception, translate: resetPasswordErrorMessage);
        return false;
    }
  }

  /// Maps a failed call onto the state. Field-level 400 errors bind to their
  /// inputs; everything else (401 bad OTP, 429, network, server) becomes a
  /// general message. Phone number and the running cooldown are preserved.
  ///
  /// [translate] customises the general message per screen (the reset screen
  /// passes [resetPasswordErrorMessage]); without it the backend's mapped
  /// message is shown verbatim.
  void _applyError(
    Exception exception, {
    String Function(AppException)? translate,
  }) {
    final appException = exception is AppException ? exception : null;

    if (appException is ValidationException) {
      final otp = appException.errorFor('otp');
      final password = appException.errorFor('newPassword');
      final phone = appException.errorFor('phoneNumber');
      final hasFieldError = otp != null || password != null || phone != null;
      if (hasFieldError) {
        state = ForgotPasswordState(
          phoneNumber: state.phoneNumber,
          resendCooldown: state.resendCooldown,
          otpError: otp,
          passwordError: password,
          phoneError: phone,
        );
        return;
      }
    }

    final message = appException == null
        ? AppStrings.serverError
        : (translate?.call(appException) ?? appException.message);

    state = ForgotPasswordState(
      phoneNumber: state.phoneNumber,
      resendCooldown: state.resendCooldown,
      errorMessage: message,
      rateLimited: appException is RateLimitException,
    );
  }

  void _startCooldown([int seconds = _resendCooldownSeconds]) {
    _timer?.cancel();
    state = state.copyWith(resendCooldown: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = state.resendCooldown - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
