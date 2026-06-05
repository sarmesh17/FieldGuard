import '../../../../core/utils/results.dart';
import '../dto/profile_response.dart';
import '../dto/update_profile_request.dart';

abstract class ProfileDataSource {
  Future<Result<ProfileResponse>> getProfile();
  Future<Result<ProfileResponse>> updateProfile(UpdateProfileRequest request);
}
