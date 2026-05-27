import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';

class NetworkExceptionMapper {
  const NetworkExceptionMapper._();

  static AppException map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(AppStrings.networkError);
      default:
        final status = e.response?.statusCode;
        if (status == 401) {
          return const UnauthorizedException(AppStrings.invalidCredentials);
        }
        final body = e.response?.data;
        final fieldErrors = _extractFieldErrors(body);
        final apiMessage = _extractApiMessage(body, fieldErrors);
        if (apiMessage != null) {
          return ValidationException(apiMessage, fieldErrors: fieldErrors);
        }
        return const ServerException(AppStrings.serverError);
    }
  }

  /// Parses the 400 `errors[]` array into typed [FieldError]s. Entries without
  /// a usable `field`/`message` pair are skipped (a 409's `errors` is `[]`).
  static List<FieldError> _extractFieldErrors(Object? body) {
    if (body is! Map<String, dynamic>) return const [];
    final errors = body['errors'];
    if (errors is! List) return const [];
    final result = <FieldError>[];
    for (final e in errors) {
      if (e is! Map) continue;
      final field = e['field'];
      final message = e['message'];
      if (field is String && message is String && message.isNotEmpty) {
        result.add(FieldError(field: field, message: message));
      }
    }
    return result;
  }

  /// User-facing message: the first field error wins over the generic
  /// top-level `message` (e.g. "Validation failed"), so a 400 shows the
  /// actionable detail; a 409 falls through to its verbatim `message`.
  static String? _extractApiMessage(Object? body, List<FieldError> fieldErrors) {
    if (fieldErrors.isNotEmpty) return fieldErrors.first.message;
    if (body is! Map<String, dynamic>) return null;
    final msg = body['message'];
    return msg is String && msg.isNotEmpty ? msg : null;
  }
}
