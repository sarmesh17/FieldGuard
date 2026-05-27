import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/approval/data/datasource/company_approval_datasource.dart';
import 'package:fieldguard/features/auth/approval/data/dto/company_approval_response.dart';

class CompanyApprovalDatasourceImpl extends CompanyApprovalDataSource
    with ApiRunner {
  final Dio _dio;

  CompanyApprovalDatasourceImpl(this._dio);

  @override
  Future<Result<CompanyApprovalResponse>> getApprovalStatus() => safeCall(
    () async {
      final response = await _dio.get(ApiConstant.companyEndpoint);
      return CompanyApprovalResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    },
  );
}
