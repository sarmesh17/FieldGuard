import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/domain/usecase/list_collections_usecase.dart';
import 'package:fieldguard/features/collections/presentation/providers/collections_list_state.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Drives a single shop's paginated, filterable collections list. `shopId` is
/// fixed at construction (the hosting shop detail screen); filters are applied
/// via [applyFilters], pagination via [loadMore].
class CollectionsListNotifier extends StateNotifier<CollectionsListState> {
  final ListCollectionsUsecase _usecase;
  final int shopId;

  static const _pageSize = 20;
  CollectionFilters _filters = const CollectionFilters();

  CollectionsListNotifier(this._usecase, this.shopId)
      : super(const CollectionsListInitial()) {
    load();
  }

  /// First-page load (also used as refresh). Resets to the current filters.
  Future<void> load() async {
    state = const CollectionsListLoading();
    final result = await _usecase(
      shopId: shopId,
      method: _filters.method,
      status: _filters.status,
      from: _filters.from,
      to: _filters.to,
      page: 1,
      limit: _pageSize,
    );
    state = switch (result) {
      Success(:final data) => CollectionsListSuccess(
          items: data.collections,
          summary: data.summary,
          pagination: data.pagination,
          filters: _filters,
        ),
      Failure(:final exception) => CollectionsListFailure(
          exception is AppException ? exception.message : 'Something went wrong',
          _filters,
        ),
    };
  }

  /// Replace the active filters and reload from page 1.
  Future<void> applyFilters(CollectionFilters filters) async {
    _filters = filters;
    await load();
  }

  /// Append the next page. No-op if not in a success state, already loading
  /// more, or no further pages.
  Future<void> loadMore() async {
    final current = state;
    if (current is! CollectionsListSuccess) return;
    if (current.loadingMore || !current.hasMore) return;

    state = current.copyWith(loadingMore: true);
    final nextPage = current.pagination.page + 1;
    final result = await _usecase(
      shopId: shopId,
      method: _filters.method,
      status: _filters.status,
      from: _filters.from,
      to: _filters.to,
      page: nextPage,
      limit: _pageSize,
    );

    // Guard: filters may have changed while the page was in flight.
    final latest = state;
    if (latest is! CollectionsListSuccess) return;

    switch (result) {
      case Success(:final data):
        state = latest.copyWith(
          items: [...latest.items, ...data.collections],
          summary: data.summary,
          pagination: data.pagination,
          loadingMore: false,
        );
      case Failure():
        // Drop the spinner, keep what we have — a transient page failure
        // shouldn't blank the list.
        state = latest.copyWith(loadingMore: false);
    }
  }
}
