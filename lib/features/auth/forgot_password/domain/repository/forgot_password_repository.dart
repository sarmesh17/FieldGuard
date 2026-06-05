import 'package:fieldguard/core/utils/results.dart';

abstract class ForgotPasswordRepository {
  /// Requests an OTP for [phoneNumber]. Resolves to [Success] whenever the
  /// backend accepts the request (always 200 for a valid format), regardless of
  /// whether the number is actually registered.
  Future<Result<void>> requestOtp(String phoneNumber);

  /// Verifies the OTP and sets the new password. On success any locally cached
  /// tokens are cleared, since the server has invalidated every session.
  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  });
}
