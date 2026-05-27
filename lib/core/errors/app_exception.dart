sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

/// A single server-side field validation error, from a 400's `errors[]`.
class FieldError {
  final String field;
  final String message;

  const FieldError({required this.field, required this.message});
}

class ValidationException extends AppException {
  /// Field-level errors from the 400 `errors[]` array (empty for a 409 or any
  /// response without per-field detail). Forms use these to set
  /// `InputDecoration.errorText` on the matching field.
  final List<FieldError> fieldErrors;

  const ValidationException(super.message, {this.fieldErrors = const []});

  /// First server message for [field], or null. Lets a form bind one field's
  /// error without scanning the list itself.
  String? errorFor(String field) {
    for (final e in fieldErrors) {
      if (e.field == field) return e.message;
    }
    return null;
  }
}

class ServerException extends AppException {
  const ServerException(super.message);
}
