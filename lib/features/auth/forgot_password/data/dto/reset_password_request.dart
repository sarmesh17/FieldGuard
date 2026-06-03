/// Body for `POST /api/v1/auth/reset-password` — verifies the OTP and sets a
/// new password.
class ResetPasswordRequest {
  final String phoneNumber;
  final String otp;
  final String newPassword;

  const ResetPasswordRequest({
    required this.phoneNumber,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      };
}
