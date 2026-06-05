import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';

abstract class SignupDataSource {
  /// Step 1 — register the company & create the admin (JSON).
  Future<Result<SignupResponse>> register(SignupRequest request);

  /// Step 2/3 — request a presigned URL and PUT the file straight to S3.
  /// Returns the storage [imageKey] to confirm later.
  Future<Result<String>> uploadDocument({
    required String filePath,
    required int companyId,
    required String accessToken,
  });

  /// Step 4 — confirm the uploaded documents on the company.
  Future<Result<void>> confirmDocuments({
    required String citizenshipImageKey,
    required String legalDocumentImageKey,
    required String accessToken,
  });
}
