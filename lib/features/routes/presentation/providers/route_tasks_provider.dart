import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/services/notification_service.dart';
import 'package:fieldguard/features/auto_geofence/service/auto_geofence_service.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Fixed id so an arrival alert is replaced by the matching departure alert
/// instead of stacking duplicates in the notification shade.
const _kGeofenceNotifId = 7001;

/// Owns the route screen's own task list — independent of the tasks-list UI
/// (which is filtered per tab). Server scopes `GET /tasks` to the caller, so a
/// plain fetch returns exactly the field agent's own tasks. Re-fetched on a
/// socket `task:status_changed` and on geofence enter/exit (via the bridge),
/// so the "navigating to" card and schedule track reality.
class RouteTasksNotifier extends StateNotifier<List<TaskSummary>> {
  final TaskDataSourceImpl _datasource;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _debounce;
  bool _disposed = false;

  RouteTasksNotifier(this._datasource) : super(const []) {
    refresh();
    _socketSub = LiveTrackingSocket.instance.onTaskStatusChanged.listen(
      (_) => refresh(),
    );
  }

  void refresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  Future<void> _fetch() async {
    try {
      // High limit + no status filter → the agent's full task set in one page;
      // the derived providers slice today / active out of it.
      final res = await _datasource.getTasks(page: 1, limit: 100);
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

/// Auto-disposed: alive only while the Routes screen (or its consumers) are
/// mounted.
final routeTasksProvider =
    StateNotifierProvider.autoDispose<RouteTasksNotifier, List<TaskSummary>>(
  (ref) => RouteTasksNotifier(
    TaskDataSourceImpl(ref.watch(_routeTasksDioProvider)),
  ),
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
final activeInProgressTaskProvider =
    Provider.autoDispose<TaskSummary?>((ref) {
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
final reachedDestinationTaskIdProvider =
    StateProvider<int?>((ref) => null);

/// Wires [AutoGeofenceService]'s read-only enter/exit events into Riverpod:
///   * ENTER → mark [reachedDestinationTaskIdProvider] (so the route card
///     swaps to ARRIVED) + heads-up notification + haptic buzz.
///   * EXIT  → clear the reached marker, fire the "task completed"
///     notification, then refresh tasks (the backend auto-completes on the
///     visit upload, so a refresh surfaces COMPLETED).
///
/// NOT auto-disposed: mounted once on login from `main.dart`. Notifications
/// have to keep firing whether or not the user is on the Routes tab (they
/// won't be, most of the time — they'll be in their pocket walking to the
/// shop), so the bridge can't be tied to a screen's lifecycle.
final geofenceEventBridgeProvider = Provider<void>((ref) {
  final service = AutoGeofenceService.instance;

  // Seed from the service in case we were rebuilt while already inside a fence.
  final already = service.insideTaskId;
  if (already != null) {
    Future.microtask(
      () => ref.read(reachedDestinationTaskIdProvider.notifier).state = already,
    );
  }

  /// Looks up a task's shop label for the notification body. Falls back to
  /// generic copy when the route-tasks cache isn't populated (e.g. the user
  /// has never opened the Routes screen this session — the bridge fires
  /// app-wide).
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

  service.onEnter = (taskId) {
    if (kDebugMode) debugPrint('[geofence-bridge] ENTER task=$taskId');
    ref.read(reachedDestinationTaskIdProvider.notifier).state = taskId;
    // Solid buzz on arrival — phone is often in a pocket; mirrors field_guard_re.
    HapticFeedback.heavyImpact();
    final label = shopLabel(taskId);
    NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'You reached your destination',
      body: 'You have arrived at $label.',
    );
  };
  service.onRealExit = (taskId) {
    if (kDebugMode) debugPrint('[geofence-bridge] REAL EXIT task=$taskId');
    final reached = ref.read(reachedDestinationTaskIdProvider);
    if (reached == taskId) {
      ref.read(reachedDestinationTaskIdProvider.notifier).state = null;
    }
    final label = shopLabel(taskId);
    NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'Task completed',
      body: 'You left $label — the task was marked completed.',
    );
    // Surface the backend's auto-completion of this task.
    try {
      ref.read(routeTasksProvider.notifier).refresh();
    } catch (_) {
      // routeTasksProvider may be disposed — that's fine, it'll re-fetch
      // the next time the Routes screen mounts.
    }
  };

  ref.onDispose(() {
    service.onEnter = null;
    service.onRealExit = null;
  });
});
