import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/auth/signup/data/datasource/signup_datasource.dart';
import 'package:fieldguard/features/auth/signup/data/datasource/signup_datasource_impl.dart';
import 'package:fieldguard/features/auth/signup/data/repository/signup_repository_impl.dart';
import 'package:fieldguard/features/auth/signup/domain/repository/signup_repository.dart';
import 'package:fieldguard/features/auth/signup/domain/usecase/signup_usecase.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_notifier.dart';
import 'package:fieldguard/features/auth/signup/presentation/providers/signup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final _signupDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final signupDataSourceProvider = Provider<SignupDataSource>(
  (ref) => SignupDatasourceImpl(ref.watch(_signupDioProvider)),
);

final signupRepositoryProvider = Provider<SignupRepository>(
  (ref) => SignupRepositoryImpl(ref.watch(signupDataSourceProvider)),
);

final signupUsecaseProvider = Provider<SignupUsecase>(
  (ref) => SignupUsecase(ref.watch(signupRepositoryProvider)),
);

final signupNotifierProvider = StateNotifierProvider<SignupNotifier, SignupState>(
  (ref) => SignupNotifier(ref.watch(signupUsecaseProvider)),
);
