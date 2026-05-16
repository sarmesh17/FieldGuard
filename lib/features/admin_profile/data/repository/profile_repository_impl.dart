import '../../../../core/utils/results.dart';
import '../../domain/repository/profile_repository.dart';
import '../datasource/profile_datasource.dart';
import '../dto/profile_response.dart';
import '../dto/update_profile_request.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<Result<ProfileResponse>> getProfile() async {
    return await dataSource.getProfile();
  }

  @override
  Future<Result<ProfileResponse>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    return await dataSource.updateProfile(request);
  }
}
