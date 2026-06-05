import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/auth/forgot_password/data/datasource/forgot_password_datasource.dart';
import 'package:fieldguard/features/auth/forgot_password/data/datasource/forgot_password_datasource_impl.dart';
import 'package:fieldguard/features/auth/forgot_password/data/repository/forgot_password_repository_impl.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/repository/forgot_password_repository.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/usecase/request_otp_usecase.dart';
import 'package:fieldguard/features/auth/forgot_password/domain/usecase/reset_password_usecase.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_notifier.dart';
import 'package:fieldguard/features/auth/forgot_password/presentation/providers/forgot_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final _forgotPasswordDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final forgotPasswordDataSourceProvider = Provider<ForgotPasswordDataSource>(
  (ref) =>
      ForgotPasswordDatasourceImpl(ref.watch(_forgotPasswordDioProvider)),
);

final forgotPasswordRepositoryProvider = Provider<ForgotPasswordRepository>(
  (ref) =>
      ForgotPasswordRepositoryImpl(ref.watch(forgotPasswordDataSourceProvider)),
);

final requestOtpUsecaseProvider = Provider<RequestOtpUsecase>(
  (ref) => RequestOtpUsecase(ref.watch(forgotPasswordRepositoryProvider)),
);

final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>(
  (ref) => ResetPasswordUsecase(ref.watch(forgotPasswordRepositoryProvider)),
);

/// Auto-disposed so each time the user leaves the flow (back to login) the
/// cooldown timer is torn down and the next visit starts clean.
final forgotPasswordNotifierProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordNotifier, ForgotPasswordState>(
  (ref) => ForgotPasswordNotifier(
    ref.watch(requestOtpUsecaseProvider),
    ref.watch(resetPasswordUsecaseProvider),
  ),
);
