/// Body for `POST /api/v1/auth/forgot-password` — requests an OTP by phone.
class ForgotPasswordRequest {
  final String phoneNumber;

  const ForgotPasswordRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}
