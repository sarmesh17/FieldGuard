import 'package:dio/dio.dart';
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
      final message = e.response?.data?['message']?.toString() ??
          'Failed to update shop. Please try again.';
      state = UpdateShopFailure(message);
    } catch (_) {
      state = const UpdateShopFailure(
          'An unexpected error occurred. Please try again.');
    }
  }
}
