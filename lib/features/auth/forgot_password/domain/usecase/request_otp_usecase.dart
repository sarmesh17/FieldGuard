import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/repository/forgot_password_repository.dart';

class RequestOtpUsecase {
  final ForgotPasswordRepository repository;

  RequestOtpUsecase(this.repository);

  Future<Result<void>> call(String phoneNumber) {
    return repository.requestOtp(phoneNumber);
  }
}
