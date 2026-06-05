import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/repository/forgot_password_repository.dart';

class ResetPasswordUsecase {
  final ForgotPasswordRepository repository;

  ResetPasswordUsecase(this.repository);

  Future<Result<void>> call({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) {
    return repository.resetPassword(
      phoneNumber: phoneNumber,
      otp: otp,
      newPassword: newPassword,
    );
  }
}
