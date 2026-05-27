import 'dart:async';

import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/config/geofence_config.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_visit_datasource.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_visit_store.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_state.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_visit.dart';
import 'package:fieldguard/features/auto_geofence/service/mutex.dart';
import 'package:flutter/foundation.dart';

/// Drains the persisted retry queue.
///
/// Exit events are persisted first (by the service) then uploaded here,
/// asynchronously, so they survive offline mode, app kill, reboot, token
/// refresh and backend downtime. Retries are idempotent — the backend
/// dedupes on `visitId`, so a resend after a dropped response never
/// duplicates a row. Failed sends back off exponentially; after
/// [GeofenceConfig.maxUploadAttempts] a visit is marked DEAD and parked.
///
/// All queue access goes through a [Mutex] so an [enqueue] can never race
/// a [flush] into a stale read-modify-write.
class GeofenceVisitUploader {
  final GeofenceVisitStore _store;
  final GeofenceVisitDatasource _datasource;
  final Mutex _mutex = Mutex();

  Timer? _retryTimer;

  GeofenceVisitUploader(this._store, this._datasource);

  /// Persist a freshly-closed visit to the queue WITHOUT uploading.
  ///
  /// Kept separate from [flush] so the caller can persist the queue entry
  /// *before* forgetting the open visit — closing that crash window means
  /// a kill mid-close never loses the visit (at worst it is recovered and
  /// re-enqueued under the same visitId, which is deduped here and again
  /// by the backend).
  Future<void> persist(GeofenceVisit visit) {
    return _mutex.run(() async {
      final queue = await _store.loadQueue();
      // Local idempotency: never double-queue the same visitId.
      if (queue.any((q) => q.visit.visitId == visit.visitId)) return;
      queue.add(
        QueuedVisit(
          visit: visit,
          attemptCount: 0,
          nextAttemptAtUtc: DateTime.now().toUtc(),
          state: GeofenceState.pendingUpload,
        ),
      );
      await _store.saveQueue(queue);
    });
  }

  /// Attempt every due, non-dead queued visit. Safe to call often (resume,
  /// connectivity regained, after enqueue, on a backoff timer).
  Future<void> flush() => _mutex.run(_drain);

  /// Core drain loop. MUST run inside [_mutex].
  Future<void> _drain() async {
    var queue = await _store.loadQueue();
    final now = DateTime.now().toUtc();

    for (final queued in List<QueuedVisit>.from(queue)) {
      if (queued.isDead) continue;
      if (queued.nextAttemptAtUtc.isAfter(now)) continue;

      final result = await _datasource.submit(queued.visit);

      // Re-resolve by visitId — the list reference is stable here (we hold
      // the mutex) but this keeps the update robust to any reordering.
      final index = queue.indexWhere(
        (q) => q.visit.visitId == queued.visit.visitId,
      );
      if (index == -1) continue;

      switch (result) {
        case Success():
          queue.removeAt(index);
        case Failure():
          final attempt = queued.attemptCount + 1;
          if (attempt >= GeofenceConfig.maxUploadAttempts) {
            queue[index] = queued.copyWith(
              attemptCount: attempt,
              state: GeofenceState.dead,
            );
            if (kDebugMode) {
              debugPrint(
                '[Geofence] visit ${queued.visit.visitId} DEAD after $attempt attempts',
              );
            }
          } else {
            queue[index] = queued.copyWith(
              attemptCount: attempt,
              nextAttemptAtUtc: now.add(_backoff(attempt)),
            );
          }
      }
      await _store.saveQueue(queue);
    }

    _scheduleNextRetry(queue);
  }

  /// base * 2^(attempt-1), capped at [GeofenceConfig.retryMaxDelay].
  Duration _backoff(int attempt) {
    final factor = 1 << (attempt - 1);
    final ms = GeofenceConfig.retryBaseDelay.inMilliseconds * factor;
    final capped = ms.clamp(0, GeofenceConfig.retryMaxDelay.inMilliseconds);
    return Duration(milliseconds: capped);
  }

  void _scheduleNextRetry(List<QueuedVisit> queue) {
    _retryTimer?.cancel();
    final pending = queue.where((q) => !q.isDead).toList();
    if (pending.isEmpty) return;

    final now = DateTime.now().toUtc();
    final soonest = pending
        .map((q) => q.nextAttemptAtUtc)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final delay = soonest.isAfter(now) ? soonest.difference(now) : Duration.zero;
    _retryTimer = Timer(delay, flush);
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
