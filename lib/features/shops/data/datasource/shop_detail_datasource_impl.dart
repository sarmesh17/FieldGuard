import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/shops/data/dto/shop_detail_response.dart';

class ShopDetailDataSourceImpl {
  final Dio _dio;

  ShopDetailDataSourceImpl(this._dio);

  Future<ShopDetailResponse> getShopDetail(String id) async {
    final response = await _dio.get('${ApiConstant.getShopsEndpoint}/$id');
    return ShopDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
