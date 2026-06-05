import 'package:dio/dio.dart';
import '../../../../core/constant/api_constant.dart';
import '../../../../core/services/session.dart';
import '../../../../core/utils/api_runner.dart';
import '../../../../core/utils/results.dart';
import '../dto/profile_response.dart';
import '../dto/update_profile_request.dart';
import 'profile_datasource.dart';

class ProfileDataSourceImpl extends ProfileDataSource with ApiRunner {
  final Dio _dio;

  ProfileDataSourceImpl(this._dio);

  @override
  Future<Result<ProfileResponse>> getProfile() => safeCall(() async {
        final response = await _dio.get(ApiConstant.getProfileEndpoint);
        return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Result<ProfileResponse>> updateProfile(
    UpdateProfileRequest request,
  ) =>
      safeCall(() async {
        // MANAGER hits their own endpoint; ADMIN hits the auth/profile endpoint.
        final isManager = await Session.isManager();
        final endpoint = isManager
            ? ApiConstant.updateManagerProfileEndpoint
            : ApiConstant.updateProfileEndpoint;

        final response = await _dio.patch(
          endpoint,
          data: request.toJson(),
        );
        return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
      });
}
