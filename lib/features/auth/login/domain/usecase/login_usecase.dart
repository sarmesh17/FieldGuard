import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/data/dto/login_response.dart';
import 'package:fieldguard/features/auth/login/domain/repository/login_repository.dart';

class LoginUsecase {
  final LoginRepository repository;

  LoginUsecase(this.repository);

  Future<Result<LoginResponse>> call(String phoneNumber, String password) {
    return repository.login(phoneNumber, password);
  }
}
