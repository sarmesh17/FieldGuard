import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/shops/data/datasource/shop_datasource.dart';
import 'package:fieldguard/features/shops/data/dto/create_shop_request.dart';
import 'package:fieldguard/features/shops/data/dto/create_shop_response.dart';

class ShopDataSourceImpl implements ShopDataSource {
  final Dio _dio;

  ShopDataSourceImpl(this._dio);

  @override
  Future<CreateShopResponse> createShop(CreateShopRequest request) async {
    final response = await _dio.post(
      ApiConstant.getShopsEndpoint,
      data: request.toJson(),
      options: Options(contentType: 'application/json'),
    );
    return CreateShopResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
