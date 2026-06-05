import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/notifications/data/notifications_datasource.dart';
import 'package:fieldguard/features/notifications/data/notifications_response.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Drives the in-app notification center: the list, the unread badge count, and
/// pagination. Loaded lazily on first watch (e.g. when the dashboard bell
/// mounts) so the badge is populated without opening the list.
final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(
    NotificationsDatasource(DioClient.createDio()),
  ),
);

class NotificationsState {
  final List<NotificationItem> items;
  final int unreadCount;
  final int total;
  final int page;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.page = 0,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  static const Object _keep = Object();

  NotificationsState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    int? total,
    int? page,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error = _keep,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
      page: page ?? this.page,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._ds) : super(const NotificationsState()) {
    load();
  }

  final NotificationsDatasource _ds;
  static const int _limit = 20;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    final res = await _ds.fetch(page: 1, limit: _limit);
    switch (res) {
      case Success(:final data):
        state = NotificationsState(
          items: data.notifications,
          unreadCount: data.unreadCount,
          total: data.total,
          page: data.page,
          hasMore: data.notifications.length < data.total,
        );
      case Failure(:final exception):
        state = state.copyWith(loading: false, error: exception.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    final res = await _ds.fetch(page: state.page + 1, limit: _limit);
    switch (res) {
      case Success(:final data):
        final items = [...state.items, ...data.notifications];
        state = state.copyWith(
          items: items,
          unreadCount: data.unreadCount,
          total: data.total,
          page: data.page,
          loadingMore: false,
          hasMore: items.length < data.total,
        );
      case Failure():
        state = state.copyWith(loadingMore: false);
    }
  }

  /// Optimistically marks one read (badge drops immediately), then persists.
  Future<void> markRead(int id) async {
    final idx = state.items.indexWhere((n) => n.id == id);
    if (idx < 0 || state.items[idx].isRead) return;
    final items = [...state.items];
    items[idx] = items[idx].markedRead(DateTime.now().toIso8601String());
    state = state.copyWith(
      items: items,
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    );
    await _ds.markRead(id); // best-effort — UI already reflects it
  }

  Future<void> refresh() => load();
}
