import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/auth/login/data/datasource/login_datasource.dart';
import 'package:fieldguard/features/auth/login/data/datasource/login_datasource_impl.dart';
import 'package:fieldguard/features/auth/login/data/repository/login_repository_impl.dart';
import 'package:fieldguard/features/auth/login/domain/repository/login_repository.dart';
import 'package:fieldguard/features/auth/login/domain/usecase/login_usecase.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_notifier.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.createDio());

final loginDataSourceProvider = Provider<LoginDataSource>(
  (ref) => LoginDatasourceImpl(ref.watch(dioProvider)),
);

final loginRepositoryProvider = Provider<LoginRepository>(
  (ref) => LoginRepositoryImpl(ref.watch(loginDataSourceProvider)),
);

final loginUsecaseProvider = Provider<LoginUsecase>(
  (ref) => LoginUsecase(ref.watch(loginRepositoryProvider)),
);

final loginNotifierProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(ref.watch(loginUsecaseProvider)),
);
