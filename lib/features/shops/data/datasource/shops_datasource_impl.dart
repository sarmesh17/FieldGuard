import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource.dart';
import 'package:fieldguard/features/shops/data/dto/shops_hierarchy_response.dart';

class ShopsDataSourceImpl implements ShopsDataSource {
  final Dio _dio;

  ShopsDataSourceImpl(this._dio);

  @override
  Future<ShopsHierarchyResponse> getShopsHierarchy({String? source}) async {
    try {
      final params = source != null ? {'source': source} : null;
      final response = await _dio.get(
        ApiConstant.getShopsEndpoint,
        queryParameters: params,
      );
      return ShopsHierarchyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }
}
