import '../../../../core/utils/results.dart';
import '../../data/dto/profile_response.dart';
import '../../data/dto/update_profile_request.dart';

abstract class ProfileRepository {
  Future<Result<ProfileResponse>> getProfile();
  Future<Result<ProfileResponse>> updateProfile(UpdateProfileRequest request);
}
