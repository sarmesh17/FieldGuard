import 'package:fieldguard/core/errors/app_exception.dart';

/// Friendly, reset-screen-specific copy for a failed `reset-password` call.
///
/// The backend keeps its messages generic on purpose (anti-enumeration), so we
/// translate the mapped [AppException] into something clear for a user who is
/// actively typing their code.
///
/// Per-field 400 validation errors ("OTP must be a 6-digit code", "Password
/// must be at least 6 characters") are handled separately and shown inline
/// under the matching field, so this only covers the *general* failures: a
/// bad/expired or burned OTP (401), a rate limit (429), network, and anything
/// unexpected.
String resetPasswordErrorMessage(AppException error) {
  if (error is UnauthorizedException) {
    // 401 — wrong/expired code, or the code is burned after too many tries.
    return error.message.toLowerCase().contains('too many')
        ? 'Too many wrong attempts. Please request a new code.'
        : 'Incorrect or expired code. Please check it or request a new one.';
  }
  if (error is RateLimitException) {
    return 'Too many attempts. Please try again shortly.';
  }
  if (error is NetworkException) {
    return 'Network error. Check your internet and try again.';
  }
  // ValidationException without a usable field error, ServerException, etc.
  return 'Something went wrong. Please try again.';
}
