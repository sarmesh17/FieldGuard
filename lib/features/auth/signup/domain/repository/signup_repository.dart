import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';

abstract class SignupRepository {
  Future<Result<SignupResponse>> register(SignupRequest request);

  Future<Result<String>> uploadDocument({
    required String filePath,
    required int companyId,
    required String accessToken,
  });

  Future<Result<void>> confirmDocuments({
    required String citizenshipImageKey,
    required String legalDocumentImageKey,
    required String accessToken,
  });
}
