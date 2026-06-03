/// Single immutable state for the whole forgot/reset-password flow.
///
/// One notifier (and one state) spans both screens so the 60-second resend
/// cooldown and the entered phone number survive the navigation from the
/// phone-entry screen to the OTP screen.
class ForgotPasswordState {
  /// The number the OTP was requested for. Set once the request is accepted and
  /// reused for both "resend" and "reset".
  final String phoneNumber;

  /// True while a request-OTP, resend, or reset call is in flight.
  final bool isLoading;

  /// General, non-field error to show (e.g. network, 401 bad-OTP, server).
  final String? errorMessage;

  /// True when [errorMessage] is a 429 rate-limit, so the UI can present it as a
  /// "slow down" warning rather than a hard error.
  final bool rateLimited;

  /// Seconds left before "Resend OTP" is allowed again. 0 means it can be sent.
  final int resendCooldown;

  /// Per-field server validation messages (from a 400 `errors[]`).
  final String? phoneError;
  final String? otpError;
  final String? passwordError;

  const ForgotPasswordState({
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
    this.rateLimited = false,
    this.resendCooldown = 0,
    this.phoneError,
    this.otpError,
    this.passwordError,
  });

  bool get canResend => resendCooldown == 0;

  ForgotPasswordState copyWith({
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
    bool? rateLimited,
    int? resendCooldown,
    String? phoneError,
    String? otpError,
    String? passwordError,
    bool clearError = false,
    bool clearFieldErrors = false,
  }) {
    return ForgotPasswordState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rateLimited: rateLimited ?? this.rateLimited,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      phoneError: clearFieldErrors ? null : (phoneError ?? this.phoneError),
      otpError: clearFieldErrors ? null : (otpError ?? this.otpError),
      passwordError:
          clearFieldErrors ? null : (passwordError ?? this.passwordError),
    );
  }
}
