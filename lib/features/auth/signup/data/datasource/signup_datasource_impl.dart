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
        final formData = FormData.fromMap({
          'companyName': request.companyName,
          'panNumber': request.panNumber,
          'adminName': request.adminName,
          'phoneNumber': request.phoneNumber,
          'password': request.password,
          'citizenshipImage': await MultipartFile.fromFile(
            request.citizenshipImagePath,
          ),
          'registrationDocument': await MultipartFile.fromFile(
            request.registrationDocPath,
          ),
        });
        final response = await _dio.post(
          ApiConstant.companyRegistration,
          data: formData,
        );
        return SignupResponse.fromJson(response.data as Map<String, dynamic>);
      });
}
