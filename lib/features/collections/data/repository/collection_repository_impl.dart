import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/datasource/collection_datasource.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionDataSource _dataSource;
  CollectionRepositoryImpl(this._dataSource);

  @override
  Future<Result<CreateCollectionResponse>> recordCollection(
    CreateCollectionRequest request,
  ) =>
      _dataSource.recordCollection(request);

  @override
  Future<Result<CreateCollectionResponse>> settleCollection(
    int id,
    SettleCollectionRequest request,
  ) =>
      _dataSource.settleCollection(id, request);

  @override
  Future<Result<OutstandingSnapshot>> shopOutstanding(int shopId) =>
      _dataSource.shopOutstanding(shopId);

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
      _dataSource.listCollections(
        shopId: shopId,
        method: method,
        status: status,
        collectedBy: collectedBy,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );

  @override
  Future<Result<OutstandingSnapshot>> setShopDue(
    int shopId,
    SetShopDueRequest request,
  ) =>
      _dataSource.setShopDue(shopId, request);
}
