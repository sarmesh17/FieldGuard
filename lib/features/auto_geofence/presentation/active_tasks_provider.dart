import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_task_datasource.dart';
import 'package:fieldguard/features/auto_geofence/service/auto_geofence_service.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Reactive source of the manager's current IN_PROGRESS tasks.
///
/// This is the PRIMARY arm/disarm trigger for [AutoGeofenceService]: the
/// moment a task is started or completed, targets change immediately
/// rather than waiting for the service's safety-net poll (which could
/// otherwise leave a geofence armed for minutes after a task ends and
/// record a spurious visit).
///
/// Reactivity comes from (a) any task UI activity — the shared
/// [tasksNotifierProvider] changing after an in-app load / status update —
/// and (b) server-pushed `task:status_changed` socket events. The list
/// itself is always an authoritative re-fetch, so it never trusts a
/// partial or differently-filtered UI list.
class ActiveInProgressTasksNotifier extends StateNotifier<List<TaskSummary>> {
  final GeofenceTaskDatasource _datasource;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _debounce;
  bool _disposed = false;

  ActiveInProgressTasksNotifier(this._datasource) : super(const []) {
    refresh();
    _socketSub = LiveTrackingSocket.instance.onTaskStatusChanged.listen(
      (_) => refresh(),
    );
  }

  /// Debounced authoritative fetch (coalesces bursts of triggers).
  void refresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  Future<void> _fetch() async {
    final result = await _datasource.fetchInProgressTasks();
    if (_disposed) return;
    switch (result) {
      case Success(:final data):
        state = data;
      case Failure():
        // Keep the last known list — a transient blip must not disarm.
        break;
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

final _activeTasksDioProvider = Provider<Dio>((ref) => DioClient.createDio());

/// Auto-disposed: tied to the geofence bridge's lifetime, so it spins up on
/// login and tears down (cancelling its socket + timers) on logout.
final activeInProgressTasksProvider =
    StateNotifierProvider.autoDispose<
      ActiveInProgressTasksNotifier,
      List<TaskSummary>
    >((ref) {
      final notifier = ActiveInProgressTasksNotifier(
        GeofenceTaskDatasource(ref.watch(_activeTasksDioProvider)),
      );
      // Any task UI activity (load / status update / refresh) re-triggers an
      // authoritative fetch — this is what makes the manager's own in-app
      // task changes flow through immediately.
      ref.listen(tasksNotifierProvider, (_, _) => notifier.refresh());
      return notifier;
    });

/// Bridges the reactive task source into [AutoGeofenceService]. Read once
/// when authenticated (keeping the source alive) and invalidated on logout.
final geofenceTaskSyncProvider = Provider<void>((ref) {
  ref.listen<List<TaskSummary>>(
    activeInProgressTasksProvider,
    (_, tasks) => AutoGeofenceService.instance.syncTasks(tasks),
    fireImmediately: true,
  );
});
