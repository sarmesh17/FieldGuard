import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: authenticate a user with email and password.
class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
