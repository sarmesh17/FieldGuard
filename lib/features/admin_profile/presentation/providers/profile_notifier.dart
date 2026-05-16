import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/dto/update_profile_request.dart';
import '../../domain/usecase/get_profile_usecase.dart';
import '../../domain/usecase/update_profile_usecase.dart';
import 'profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  ProfileNotifier(this.getProfileUseCase, this.updateProfileUseCase)
      : super(const ProfileInitial());

  Future<void> fetchProfile() async {
    state = const ProfileLoading();
    final result = await getProfileUseCase();

    state = switch (result) {
      Success(:final data) => ProfileSuccess(data),
      Failure(:final exception) => ProfileFailure(
          exception is AppException
              ? exception.message
              : 'Failed to fetch profile',
        ),
    };
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    state = const ProfileUpdating();
    final result = await updateProfileUseCase(request);

    state = switch (result) {
      Success(:final data) => ProfileUpdateSuccess(data),
      Failure(:final exception) => ProfileUpdateFailure(
          exception is AppException
              ? exception.message
              : 'Failed to update profile',
        ),
    };
  }
}
