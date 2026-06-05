import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/datasource/signup_datasource.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';

class SignupDatasourceImpl extends SignupDataSource with ApiRunner {
  final Dio _dio;
  SignupDatasourceImpl(this._dio);

  @override
  Future<Result<SignupResponse>> register(SignupRequest request) =>
      safeCall(() async {
        final response = await _dio.post(
          ApiConstant.companyRegistration,
          data: request.toJson(),
        );
        return SignupResponse.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Result<String>> uploadDocument({
    required String filePath,
    required int companyId,
    required String accessToken,
  }) => safeCall(() async {
    final bytes = await File(filePath).readAsBytes();
    final type = _detectType(filePath);

    final presignedRes = await _dio.get(
      ApiConstant.presignedUrlEndpoint,
      queryParameters: {
        'category': 'company',
        'entityId': companyId,
        'ext': type.ext,
        'mimeType': type.mime,
        'fileSize': bytes.length,
      },
      options: Options(
        headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
      ),
    );

    final data = presignedRes.data as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final imageKey = data['imageKey'] as String;

    await _putToS3(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: type.mime,
    );
    return imageKey;
  });

  @override
  Future<Result<void>> confirmDocuments({
    required String citizenshipImageKey,
    required String legalDocumentImageKey,
    required String accessToken,
  }) => safeCall(() async {
    await _dio.patch(
      ApiConstant.companyEndpoint,
      data: {
        'citizenshipImageKey': citizenshipImageKey,
        'legalDocumentImageKey': legalDocumentImageKey,
      },
      options: Options(
        headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
      ),
    );
  });

  Future<void> _putToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    int maxAttempts = 3,
  }) async {
    final s3Dio = Dio();
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await s3Dio.put<void>(
          uploadUrl,
          data: Stream.fromIterable([bytes]),
          options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: contentType,
              HttpHeaders.contentLengthHeader: bytes.length,
            },
            responseType: ResponseType.bytes,
          ),
        );
        return;
      } catch (_) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  ({String ext, String mime}) _detectType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => (ext: 'png', mime: 'image/png'),
      'pdf' => (ext: 'pdf', mime: 'application/pdf'),
      _ => (ext: 'jpg', mime: 'image/jpeg'),
    };
  }
}
