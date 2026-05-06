/// Thrown when a remote API call fails.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

/// Thrown when reading from local cache fails.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}
