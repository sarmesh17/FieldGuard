import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/collections/data/datasource/collection_datasource.dart';
import 'package:fieldguard/features/collections/data/datasource/collection_datasource_impl.dart';
import 'package:fieldguard/features/collections/data/repository/collection_repository_impl.dart';
import 'package:fieldguard/features/collections/domain/repository/collection_repository.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/domain/usecase/get_shop_outstanding_usecase.dart';
import 'package:fieldguard/features/collections/domain/usecase/list_collections_usecase.dart';
import 'package:fieldguard/features/collections/domain/usecase/record_collection_usecase.dart';
import 'package:fieldguard/features/collections/domain/usecase/set_shop_due_usecase.dart';
import 'package:fieldguard/features/collections/domain/usecase/settle_collection_usecase.dart';
import 'package:fieldguard/features/collections/presentation/providers/collections_list_notifier.dart';
import 'package:fieldguard/features/collections/presentation/providers/collections_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final _collectionDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final _collectionDatasourceProvider = Provider<CollectionDataSource>(
  (ref) => CollectionDataSourceImpl(ref.watch(_collectionDioProvider)),
);

final _collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => CollectionRepositoryImpl(ref.watch(_collectionDatasourceProvider)),
);

final recordCollectionUsecaseProvider = Provider<RecordCollectionUsecase>(
  (ref) => RecordCollectionUsecase(ref.watch(_collectionRepositoryProvider)),
);

final listCollectionsUsecaseProvider = Provider<ListCollectionsUsecase>(
  (ref) => ListCollectionsUsecase(ref.watch(_collectionRepositoryProvider)),
);

final settleCollectionUsecaseProvider = Provider<SettleCollectionUsecase>(
  (ref) => SettleCollectionUsecase(ref.watch(_collectionRepositoryProvider)),
);

final _getShopOutstandingUsecaseProvider = Provider<GetShopOutstandingUsecase>(
  (ref) => GetShopOutstandingUsecase(ref.watch(_collectionRepositoryProvider)),
);

final setShopDueUsecaseProvider = Provider<SetShopDueUsecase>(
  (ref) => SetShopDueUsecase(ref.watch(_collectionRepositoryProvider)),
);

/// A shop's money snapshot, keyed by shopId. AutoDisposed; invalidate it to
/// refresh after a collection is recorded/settled.
final shopOutstandingProvider =
    FutureProvider.autoDispose.family<OutstandingSnapshot, int>(
  (ref, shopId) async {
    final result =
        await ref.watch(_getShopOutstandingUsecaseProvider)(shopId);
    return switch (result) {
      Success(:final data) => data,
      Failure(:final exception) => throw exception,
    };
  },
);

/// Paginated collections list for one shop, keyed by shopId. Auto-disposed so
/// it starts fresh each time a shop detail screen opens.
final shopCollectionsProvider = StateNotifierProvider.autoDispose
    .family<CollectionsListNotifier, CollectionsListState, int>(
  (ref, shopId) => CollectionsListNotifier(
    ref.watch(listCollectionsUsecaseProvider),
    shopId,
  ),
);
