import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/shops/data/datasource/update_shop_datasource.dart';
import 'package:fieldguard/features/shops/data/dto/update_shop_request.dart';

class UpdateShopDataSourceImpl implements UpdateShopDataSource {
  final Dio _dio;

  UpdateShopDataSourceImpl(this._dio);

  @override
  Future<void> updateShop(int id, UpdateShopRequest request) async {
    await _dio.patch(
      '${ApiConstant.updateShopEndpoint}/$id',
      data: request.toJson(),
      options: Options(contentType: 'application/json'),
    );
  }
}
