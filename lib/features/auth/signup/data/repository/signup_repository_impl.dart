import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/signup/data/datasource/signup_datasource.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_request.dart';
import 'package:fieldguard/features/auth/signup/data/dto/signup_response.dart';
import 'package:fieldguard/features/auth/signup/domain/repository/signup_repository.dart';

class SignupRepositoryImpl extends SignupRepository {
  final SignupDataSource _dataSource;
  SignupRepositoryImpl(this._dataSource);

  @override
  Future<Result<SignupResponse>> register(SignupRequest request) =>
      _dataSource.register(request);

  @override
  Future<Result<String>> uploadDocument({
    required String filePath,
    required int companyId,
    required String accessToken,
  }) => _dataSource.uploadDocument(
    filePath: filePath,
    companyId: companyId,
    accessToken: accessToken,
  );

  @override
  Future<Result<void>> confirmDocuments({
    required String citizenshipImageKey,
    required String legalDocumentImageKey,
    required String accessToken,
  }) => _dataSource.confirmDocuments(
    citizenshipImageKey: citizenshipImageKey,
    legalDocumentImageKey: legalDocumentImageKey,
    accessToken: accessToken,
  );
}
