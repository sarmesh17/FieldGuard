import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/forgot_password_request.dart';
import 'package:fieldguard/features/auth/forgot_password/data/dto/reset_password_request.dart';

abstract class ForgotPasswordDataSource {
  /// Requests an OTP. The backend always answers 200 with a generic message
  /// (it never reveals whether the number is registered), so success here only
  /// means "the request was accepted", not "an OTP was actually sent".
  Future<Result<void>> forgotPassword(ForgotPasswordRequest request);

  /// Verifies the OTP and sets the new password. On success every existing
  /// session is invalidated server-side and the user must log in again.
  Future<Result<void>> resetPassword(ResetPasswordRequest request);
}
