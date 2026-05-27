import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_request.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/data/dto/settle_collection_request.dart';

abstract class CollectionDataSource {
  Future<Result<CreateCollectionResponse>> recordCollection(
    CreateCollectionRequest request,
  );

  /// `PATCH /api/v1/collections/{id}/settle` — move a PENDING cheque to
  /// CLEARED or BOUNCED (ADMIN/MANAGER). Returns the same shape as the create
  /// endpoint: `{collection, outstanding, smsPreview}`.
  Future<Result<CreateCollectionResponse>> settleCollection(
    int id,
    SettleCollectionRequest request,
  );

  /// `GET /api/v1/collections/shops/{shopId}/outstanding` — money snapshot for
  /// a shop: total_due, collected, pending_cheques, outstanding. Pending
  /// cheques are reported separately and don't reduce outstanding until
  /// cleared.
  Future<Result<OutstandingSnapshot>> shopOutstanding(int shopId);

  /// `GET /api/v1/collections` — role-scoped, paginated, with filter-aware
  /// summary totals. Role scoping (EMPLOYEE self / MANAGER self+reports /
  /// ADMIN all) is applied server-side; the query params only narrow further.
  Future<Result<CollectionsListResponse>> listCollections({
    int? shopId,
    String? method, // CASH | CHEQUE
    String? status, // PENDING | CLEARED | BOUNCED
    int? collectedBy,
    String? from, // ISO date-time
    String? to, // ISO date-time
    int page,
    int limit,
  });

  /// `PUT /api/v1/collections/shops/{shopId}/due` — set or adjust a shop's
  /// total due amount (ADMIN/MANAGER). Returns the updated money snapshot.
  Future<Result<OutstandingSnapshot>> setShopDue(
    int shopId,
    SetShopDueRequest request,
  );
}
