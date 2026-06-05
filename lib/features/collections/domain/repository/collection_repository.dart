import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';

abstract class CollectionRepository {
  Future<Result<CreateCollectionResponse>> recordCollection(
    CreateCollectionRequest request,
  );

  Future<Result<CreateCollectionResponse>> settleCollection(
    int id,
    SettleCollectionRequest request,
  );

  Future<Result<OutstandingSnapshot>> shopOutstanding(int shopId);

  Future<Result<CollectionsListResponse>> listCollections({
    int? shopId,
    String? method,
    String? status,
    int? collectedBy,
    String? from,
    String? to,
    int page,
    int limit,
  });

  Future<Result<OutstandingSnapshot>> setShopDue(
    int shopId,
    SetShopDueRequest request,
  );
}
