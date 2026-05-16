import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/networks/dio_client.dart';
import '../../data/datasource/profile_datasource.dart';
import '../../data/datasource/profile_datasource_impl.dart';
import '../../data/repository/profile_repository_impl.dart';
import '../../domain/repository/profile_repository.dart';
import '../../domain/usecase/get_profile_usecase.dart';
import '../../domain/usecase/update_profile_usecase.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

final profileDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final profileDataSourceProvider = Provider<ProfileDataSource>(
  (ref) => ProfileDataSourceImpl(ref.watch(profileDioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileDataSourceProvider)),
);

final getProfileUsecaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final updateProfileUsecaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(
    ref.watch(getProfileUsecaseProvider),
    ref.watch(updateProfileUsecaseProvider),
  ),
);
