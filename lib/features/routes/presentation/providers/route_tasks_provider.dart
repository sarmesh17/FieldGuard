import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/background_location_service.dart';
import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Owns the route screen's own task list — independent of the tasks-list UI
/// (which is filtered per tab). Server scopes `GET /tasks` to the caller, so a
/// plain fetch returns exactly the field agent's own tasks. Re-fetched on a
/// socket `task:status_changed` and on geofence enter/exit (via the bridge),
/// so the "navigating to" card and schedule track reality.
class RouteTasksNotifier extends StateNotifier<List<TaskSummary>> {
  final TaskDataSourceImpl _datasource;
  final int? _userId;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _debounce;
  bool _disposed = false;

  RouteTasksNotifier(this._datasource, this._userId) : super(const []) {
    refresh();
    _socketSub = LiveTrackingSocket.instance.onTaskStatusChanged.listen(
      (_) => refresh(),
    );
  }

  void refresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  /// Replace (or insert) the task with the same id, in place. Used when an
  /// authoritative server response — e.g. a geofence-visits POST that just
  /// auto-completed the task — already carries the post-write task, so we can
  /// flip its status instantly without waiting on a refetch.
  void upsertTask(TaskSummary task) {
    if (_disposed) return;
    final idx = state.indexWhere((t) => t.id == task.id);
    if (idx < 0) {
      state = [task, ...state];
    } else {
      final next = [...state];
      next[idx] = task;
      state = next;
    }
  }

  Future<void> _fetch() async {
    try {
      // Scoped to the logged-in user's own assigned tasks only, so a
      // Manager's route screen never shows tasks assigned to their
      // employees. The backend's `userId` param filters by assignee_id.
      final res = await _datasource.getTasks(
        page: 1,
        limit: 100,
        userId: _userId,
      );
      if (!_disposed) state = res.tasks;
    } catch (_) {
      // Keep the last known list on a transient failure — never blank the
      // card/schedule on a network blip.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socketSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

final _routeTasksDioProvider = Provider<Dio>((ref) => DioClient.createDio());

/// Provides the logged-in user's ID from the JWT, cached for the session.
final _currentUserIdProvider = FutureProvider<int?>((ref) => Session.userId());

/// Auto-disposed: alive only while the Routes screen (or its consumers) are
/// mounted. Fetches ONLY tasks assigned to the current user (via userId param).
final routeTasksProvider =
    StateNotifierProvider.autoDispose<RouteTasksNotifier, List<TaskSummary>>(
      (ref) {
        final userId = ref.watch(_currentUserIdProvider).value;
        return RouteTasksNotifier(
          TaskDataSourceImpl(ref.watch(_routeTasksDioProvider)),
          userId,
        );
      },
    );

/// Count of today's tasks — the AppBar badge ("N Tasks").
final todayTaskCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(todayTasksProvider).length;
});

/// Today's tasks, active-first then by due time — drives the schedule list and
/// the count badge from one computation.
final todayTasksProvider = Provider.autoDispose<List<TaskSummary>>((ref) {
  final tasks = ref.watch(routeTasksProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final today = <TaskSummary>[];
  for (final t in tasks) {
    final due = DateTime.tryParse(t.dueDate)?.toLocal();
    if (due == null) continue;
    if (due.isBefore(dayStart) || !due.isBefore(dayEnd)) continue;
    today.add(t);
  }

  int rank(String s) => switch (s) {
    'IN_PROGRESS' => 0,
    'PENDING' => 1,
    'COMPLETED' => 2,
    'CANCELLED' => 3,
    _ => 4,
  };
  today.sort((a, b) {
    final r = rank(a.status).compareTo(rank(b.status));
    if (r != 0) return r;
    final da = DateTime.tryParse(a.dueDate);
    final db = DateTime.tryParse(b.dueDate);
    if (da == null || db == null) return 0;
    return da.compareTo(db);
  });
  return today;
});

/// The single task the agent is "currently doing" — the first IN_PROGRESS task
/// with parseable shop coordinates. Null → the route screen shows its plain
/// "no active task" state.
final activeInProgressTaskProvider = Provider.autoDispose<TaskSummary?>((ref) {
  final tasks = ref.watch(routeTasksProvider);
  for (final t in tasks) {
    if (t.status != 'IN_PROGRESS') continue;
    if (taskShopLatLng(t) == null) continue;
    return t;
  }
  return null;
});

/// The task whose geofence the agent has currently reached (is inside), or
/// null. Set by [geofenceEventBridgeProvider] on a geofence ENTER and cleared
/// on a real EXIT — NOT a local distance check, so it can't disagree with the
/// detection stream. The route screen swaps its card to "ARRIVED" on this.
final reachedDestinationTaskIdProvider = StateProvider<int?>((ref) => null);

/// Bridges the background-service isolate's enter/exit events into Riverpod:
///   * ENTER → mark [reachedDestinationTaskIdProvider] (so the route card
///     swaps to ARRIVED) + heads-up notification (named) + haptic buzz.
///   * EXIT  → clear the reached marker, fire the "task completed"
///     notification, then refresh tasks (the backend auto-completes on the
///     visit upload, so a refresh surfaces COMPLETED).
///   * UPLOADED → refresh so the COMPLETED status surfaces (offline path).
///
/// Detection itself runs in the background-service isolate (surviving an
/// app-kill); these events are forwarded over [BackgroundLocationService.
/// geofenceEvents] and only arrive while the UI is alive. The isolate ALSO
/// fires a generic alert with the SAME notification id, so when the app is
/// dead the alert still shows, and when alive this named one simply overwrites
/// it — never a duplicate.
///
/// NOT auto-disposed: mounted once on login from `main.dart`. The user is
/// rarely on the Routes tab when they reach a geofence, so it can't be tied to
/// a screen's lifecycle.
final geofenceEventBridgeProvider = Provider<void>((ref) {
  /// Looks up a task's shop label for the notification body. Falls back to
  /// generic copy when the route-tasks cache isn't populated.
  String shopLabel(int taskId) {
    try {
      final tasks = ref.read(routeTasksProvider);
      for (final t in tasks) {
        if (t.id == taskId) return t.shop?.name ?? t.title;
      }
    } catch (_) {
      // routeTasksProvider may be disposed → fall through to generic copy.
    }
    return 'your destination';
  }

  final sub = BackgroundLocationService.geofenceEvents().listen((event) {
    if (event == null) return;
    final type = event['type'] as String?;
    final taskId = (event['taskId'] as num?)?.toInt();
    if (taskId == null) return;

    switch (type) {
      case 'enter':
        if (kDebugMode) debugPrint('[geofence-bridge] ENTER task=$taskId');
        ref.read(reachedDestinationTaskIdProvider.notifier).state = taskId;
        HapticFeedback.heavyImpact();
        NotificationService.instance.show(
          id: NotificationService.geofenceAlertId,
          title: 'You reached your destination',
          body: 'You have arrived at ${shopLabel(taskId)}.',
        );
      case 'exit':
        if (kDebugMode) debugPrint('[geofence-bridge] EXIT task=$taskId');
        if (ref.read(reachedDestinationTaskIdProvider) == taskId) {
          ref.read(reachedDestinationTaskIdProvider.notifier).state = null;
        }
        NotificationService.instance.show(
          id: NotificationService.geofenceAlertId,
          title: 'Task completed',
          body:
              'You left ${shopLabel(taskId)} — the task was marked '
              'completed.',
        );
        _refreshRouteTasks(ref);
      case 'uploaded':
        if (kDebugMode) {
          debugPrint('[geofence-bridge] visit uploaded task=$taskId');
        }
        _refreshRouteTasks(ref);
    }
  });

  ref.onDispose(sub.cancel);
});

void _refreshRouteTasks(Ref ref) {
  try {
    ref.read(routeTasksProvider.notifier).refresh();
  } catch (_) {
    // routeTasksProvider may be disposed — fine, it re-fetches on next mount.
  }
}
