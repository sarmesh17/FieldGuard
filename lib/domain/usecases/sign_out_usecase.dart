import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case: sign out the currently authenticated user.
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
}
