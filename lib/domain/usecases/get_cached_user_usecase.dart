import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: retrieve the currently cached (logged-in) user, if any.
class GetCachedUserUseCase {
  final AuthRepository _repository;

  const GetCachedUserUseCase(this._repository);

  Future<Either<Failure, User?>> call() => _repository.getCachedUser();
}
