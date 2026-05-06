import 'package:dartz/dartz.dart';

/// Base class for all domain-level failures.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Failure originating from a server / remote data source.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

/// Failure originating from local cache / storage.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A cache error occurred.']);
}

/// Failure for network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Failure for unexpected / unknown errors.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

/// Convenience typedef for use-case return types.
typedef FutureEither<T> = Future<Either<Failure, T>>;
