import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/core/utils/results.dart';

mixin ApiRunner {
  Future<Result<T>> safeCall<T>(Future<T> Function() fn) async {
    try {
      return Success(await fn());
    } on DioException catch (e) {
      return Failure(NetworkExceptionMapper.map(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (_) {
      return Failure(const ServerException(AppStrings.serverError));
    }
  }
}
