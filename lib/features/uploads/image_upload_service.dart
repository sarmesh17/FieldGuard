import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

enum UploadStatus { idle, uploading, done, error }

class UploadResult {
  final String imageKey;
  final String? publicUrl;

  const UploadResult({required this.imageKey, this.publicUrl});
}

class ImageUploadService {
  final Dio _authDio;

  ImageUploadService(this._authDio);

  Future<UploadResult> upload({
    required String filePath,
    required String category,
    required int entityId,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);

    final compressed = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 1080,
      minHeight: 1080,
      quality: 85,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (compressed == null) throw Exception('Image compression failed');

    final presignedRes = await _authDio.get(
      ApiConstant.presignedUrlEndpoint,
      queryParameters: {
        'category': category,
        'entityId': entityId,
        'ext': 'jpg',
        'mimeType': 'image/jpeg',
        'fileSize': compressed.length,
      },
    );

    final uploadUrl = presignedRes.data['uploadUrl'] as String;
    final imageKey = presignedRes.data['imageKey'] as String;
    final publicUrl = presignedRes.data['publicUrl'] as String?;

    await _putWithRetry(
      uploadUrl: uploadUrl,
      bytes: compressed,
      onProgress: onProgress,
    );

    return UploadResult(imageKey: imageKey, publicUrl: publicUrl);
  }

  Future<void> _putWithRetry({
    required String uploadUrl,
    required List<int> bytes,
    void Function(double)? onProgress,
    int maxAttempts = 3,
  }) async {
    final s3Dio = Dio();
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await s3Dio.put<void>(
          uploadUrl,
          data: Stream.fromIterable([bytes]),
          options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: 'image/jpeg',
              HttpHeaders.contentLengthHeader: bytes.length,
            },
            responseType: ResponseType.bytes,
          ),
          onSendProgress: (sent, total) {
            if (total > 0) onProgress?.call(sent / total);
          },
        );
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
}
