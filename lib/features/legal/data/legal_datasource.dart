import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';

/// Reads the current legal document version from the backend, which is the
/// source of truth for the `termsVersion` sent with consent on register/login.
class LegalDatasource with ApiRunner {
  final Dio _dio;
  LegalDatasource(this._dio);

  /// `GET /api/v1/legal/version` → `{ "version": "2026-05-31" }`.
  Future<Result<String>> fetchVersion() => safeCall(() async {
    final response = await _dio.get(ApiConstant.legalVersionEndpoint);
    final data = response.data as Map<String, dynamic>;
    // Flat shape per the API contract; tolerate a wrapped `data` envelope too.
    final version =
        data['version'] ?? (data['data'] as Map<String, dynamic>?)?['version'];
    return version as String;
  });
}
