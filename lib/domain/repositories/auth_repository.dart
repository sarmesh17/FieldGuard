import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Contract for authentication operations.
/// Implementations live in the data layer.
abstract class AuthRepository {
  /// Signs in with [email] and [password].
  /// Returns a [User] on success or a [Failure] on error.
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Signs out the currently authenticated user.
  Future<Either<Failure, void>> signOut();

  /// Returns the currently cached user, if any.
  Future<Either<Failure, User?>> getCachedUser();
}
