import 'package:dio/dio.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/network_exception_mapper.dart';
import 'package:fieldguard/features/shops/data/datasource/update_shop_datasource.dart';
import 'package:fieldguard/features/shops/data/dto/update_shop_request.dart';
import 'package:fieldguard/features/shops/presentation/providers/update_shop_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class UpdateShopNotifier extends StateNotifier<UpdateShopState> {
  final UpdateShopDataSource _dataSource;

  UpdateShopNotifier(this._dataSource) : super(const UpdateShopInitial());

  Future<void> updateShop(int id, UpdateShopRequest request) async {
    state = const UpdateShopLoading();
    try {
      await _dataSource.updateShop(id, request);
      state = const UpdateShopSuccess();
    } on DioException catch (e) {
      // Prefer the specific field error (e.g. an invalid-format 400 on
      // contactPhone) over the generic top-level message; the 409
      // phone-conflict message is shown verbatim via the top-level `message`.
      final mapped = NetworkExceptionMapper.map(e);
      final phoneError = mapped is ValidationException
          ? mapped.errorFor('contactPhone')
          : null;
      final isPhoneConflict = e.response?.statusCode == 409 &&
          mapped.message.toLowerCase().contains('phone');
      state = UpdateShopFailure(
        mapped.message,
        phoneError: phoneError ?? (isPhoneConflict ? mapped.message : null),
      );
    } catch (_) {
      state = const UpdateShopFailure(
          'An unexpected error occurred. Please try again.');
    }
  }
}
