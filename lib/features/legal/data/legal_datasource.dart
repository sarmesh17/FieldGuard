import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/legal/data/legal_content_response.dart';

/// Reads the legal documents from the backend (the source of truth): the
/// lightweight version for consent checks, and the full Terms/Privacy content
/// for the legal screen.
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

  /// `GET /api/v1/legal/content` → full Terms & Privacy text. Public, no auth.
  Future<Result<LegalContentResponse>> fetchContent() => safeCall(() async {
    final response = await _dio.get(ApiConstant.legalContentEndpoint);
    final data = response.data as Map<String, dynamic>;
    // Tolerate a wrapped `data` envelope like fetchVersion does.
    final body = data['documents'] != null
        ? data
        : (data['data'] as Map<String, dynamic>? ?? data);
    return LegalContentResponse.fromJson(body);
  });
}
