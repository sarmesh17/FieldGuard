import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/utils/api_runner.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/datasource/collection_datasource.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';

class CollectionDataSourceImpl
    with ApiRunner
    implements CollectionDataSource {
  final Dio _dio;
  CollectionDataSourceImpl(this._dio);

  @override
  Future<Result<CreateCollectionResponse>> recordCollection(
    CreateCollectionRequest request,
  ) =>
      safeCall(() async {
        final res = await _dio.post(
          ApiConstant.collectionsEndpoint,
          data: request.toJson(),
        );
        return CreateCollectionResponse.fromJson(
          res.data as Map<String, dynamic>,
        );
      });

  @override
  Future<Result<CollectionsListResponse>> listCollections({
    int? shopId,
    String? method,
    String? status,
    int? collectedBy,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) =>
      safeCall(() async {
        final params = <String, dynamic>{'page': page, 'limit': limit};
        if (shopId != null) params['shopId'] = shopId;
        if (method != null) params['method'] = method;
        if (status != null) params['status'] = status;
        if (collectedBy != null) params['collectedBy'] = collectedBy;
        if (from != null && from.isNotEmpty) params['from'] = from;
        if (to != null && to.isNotEmpty) params['to'] = to;

        final res = await _dio.get(
          ApiConstant.collectionsEndpoint,
          queryParameters: params,
        );
        return CollectionsListResponse.fromJson(
          res.data as Map<String, dynamic>,
        );
      });

  @override
  Future<Result<CreateCollectionResponse>> settleCollection(
    int id,
    SettleCollectionRequest request,
  ) =>
      safeCall(() async {
        final res = await _dio.patch(
          '${ApiConstant.collectionsEndpoint}/$id/settle',
          data: request.toJson(),
        );
        return CreateCollectionResponse.fromJson(
          res.data as Map<String, dynamic>,
        );
      });

  @override
  Future<Result<OutstandingSnapshot>> shopOutstanding(int shopId) =>
      safeCall(() async {
        final res = await _dio.get(
          '${ApiConstant.collectionsEndpoint}/shops/$shopId/outstanding',
        );
        return OutstandingSnapshot.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<Result<OutstandingSnapshot>> setShopDue(
    int shopId,
    SetShopDueRequest request,
  ) =>
      safeCall(() async {
        final res = await _dio.put(
          '${ApiConstant.collectionsEndpoint}/shops/$shopId/due',
          data: request.toJson(),
        );
        return OutstandingSnapshot.fromJson(res.data as Map<String, dynamic>);
      });
}
