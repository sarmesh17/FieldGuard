import 'dart:async';
import 'dart:math';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/location_tracker.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auto_geofence/config/geofence_config.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_task_datasource.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_visit_datasource.dart';
import 'package:fieldguard/features/auto_geofence/data/geofence_visit_store.dart';
import 'package:fieldguard/features/auto_geofence/domain/geo_fix.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_state.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_target.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_visit.dart';
import 'package:fieldguard/features/auto_geofence/domain/open_visit.dart';
import 'package:fieldguard/features/auto_geofence/service/geofence_geo.dart';
import 'package:fieldguard/features/auto_geofence/service/geofence_logger.dart';
import 'package:fieldguard/features/auto_geofence/service/geofence_visit_uploader.dart';
import 'package:fieldguard/features/auto_geofence/service/mutex.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

final _log = GeofenceLogger.instance;

/// The single source of truth for automatic geofence visit tracking.
///
/// Owns the location stream, the persisted state machine, recovery and the
/// retry queue. Nothing else (screens, widgets, providers) ever drives
/// detection — that is what stops duplicate enter/exit events.
///
/// Lifetime: [start] is called once the session is authenticated and
/// [stop] on logout/expiry. While running, the tracker is ARMED only while
/// the manager has at least one IN_PROGRESS task with valid shop
/// coordinates; with none it is DISARMED and the location stream is off.
///
/// Recoverability is prioritised over real-time precision: the open visit
/// and the queue are persisted to disk, and an interrupted visit (kill,
/// reboot, permission revoked, GPS lost) is closed from the last
/// in-geofence fix with `exitEstimated = true`.
class AutoGeofenceService with WidgetsBindingObserver {
  AutoGeofenceService._();
  static final AutoGeofenceService instance = AutoGeofenceService._();

  final GeofenceVisitStore _store = GeofenceVisitStore();
  final GeofenceTaskDatasource _taskDatasource = GeofenceTaskDatasource(
    DioClient.createDio(),
  );
  late final GeofenceVisitUploader _uploader = GeofenceVisitUploader(
    _store,
    GeofenceVisitDatasource(DioClient.createDio()),
    // Forward upload-success events through the service so a single
    // app-level listener (the geofence bridge) sees them — keeps the
    // public surface coherent.
    onUploaded: (taskId, task) {
      final cb = onVisitUploaded;
      if (cb != null) cb(taskId, task);
    },
  );

  /// Serialises every state mutation (fix handling, task application,
  /// recovery, visit close) so persisted state never suffers a stale
  /// read-modify-write.
  final Mutex _mutex = Mutex();

  /// Observable state, mainly for diagnostics — the system has no UI.
  final ValueNotifier<GeofenceState> stateListenable = ValueNotifier(
    GeofenceState.disarmed,
  );

  // ── Read-only event callbacks ──────────────────────────────────────
  // Set by the app (a provider) to react to live geofence transitions for
  // UI only — they do NOT drive detection or recording, which stay wholly
  // owned by this service. Fired off the mutex via microtask so a slow
  // listener can't stall detection. Mirror of the field-agent route UI's
  // arrival handling.

  /// Fired when the agent ENTERS a target's geofence (a visit opens).
  void Function(int taskId)? onEnter;

  /// Fired on a real, observed EXIT (not an app-kill/permission-loss
  /// estimate). The route UI uses this to clear its "arrived" state.
  void Function(int taskId)? onRealExit;

  /// Fired after a queued visit successfully uploads.
  ///
  /// [task] is the server's authoritative post-write task — when the backend
  /// auto-completion fired, its status is `COMPLETED`. Callers can splice it
  /// straight into local state for an instant UI flip (no extra GET). [task]
  /// is null on an idempotent duplicate that didn't trigger completion or on
  /// an unexpected response shape — fall back to a refresh in that case.
  ///
  /// Critical for the offline path: an exit while offline persists the visit;
  /// this fires later when the upload finally lands.
  void Function(int taskId, TaskSummary? task)? onVisitUploaded;

  /// The task whose geofence the agent is currently INSIDE, or null. Lets a
  /// UI rebuilt from scratch (e.g. after returning from background) know the
  /// user has already arrived, so it won't redraw a route to a shop they're
  /// already standing at.
  int? _insideTaskId;
  int? get insideTaskId => _insideTaskId;

  /// Ref-count token for the shared [LocationTracker] stream.
  final Object _locationToken = Object();

  StreamSubscription<Position>? _positionSub;
  Timer? _taskPollTimer;
  bool _started = false;
  bool _refreshing = false;

  List<GeofenceTarget> _targets = const [];
  OpenVisit? _openVisit;
  GeoFix? _lastFix;

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Start tracking. Idempotent. Recovers any visit left open by a prior
  /// process death, resends queued visits, then arms from current tasks.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _log.info('Lifecycle', 'Service STARTED — recovering open visits & arming');
    WidgetsBinding.instance.addObserver(this);

    await _mutex.run(_recoverOpenVisit);
    await _uploader.flush();

    await _refreshTasks();
    _taskPollTimer = Timer.periodic(
      GeofenceConfig.taskPollInterval,
      (_) => _onPollTick(),
    );
  }

  /// Stop tracking (logout / session expiry). The persisted open visit and
  /// retry queue are intentionally KEPT so they survive logout/login; the
  /// next [start] recovers and resends them.
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _log.info('Lifecycle', 'Service STOPPED (logout/session expiry)');
    WidgetsBinding.instance.removeObserver(this);
    _taskPollTimer?.cancel();
    _taskPollTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await LocationTracker.instance.release(_locationToken);
    _uploader.dispose();
    _targets = const [];
    _openVisit = null; // in-memory only — disk copy is retained
    _lastFix = null;
    _setState(GeofenceState.disarmed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, reconcile: tasks may have changed and queued uploads may
    // be due. The Android foreground service keeps the stream alive while
    // backgrounded, so there is nothing to restart here.
    if (state == AppLifecycleState.resumed && _started) {
      unawaited(_onPollTick());
    }
  }

  Future<void> _onPollTick() async {
    await _refreshTasks();
    await _checkStaleVisit();
    await _uploader.flush();
  }

  /// Force an immediate task re-fetch (and arm/disarm reconcile). Used by the
  /// background-service isolate when the UI pings it after an in-app task
  /// change, so arming is instant instead of waiting for the safety-net poll.
  Future<void> refreshNow() async {
    if (!_started) return;
    await _refreshTasks();
  }

  /// Reactive task feed — the PRIMARY arm/disarm trigger.
  ///
  /// Called by the task-state bridge the instant the manager's IN_PROGRESS
  /// tasks change (in-app start/complete, or a server-pushed status
  /// event), so arming/disarming is immediate instead of waiting for the
  /// safety-net poll. No-op until the service is started (authenticated).
  Future<void> syncTasks(List<TaskSummary> tasks) async {
    if (!_started) return;
    _log.debug('Tasks', 'syncTasks called with ${tasks.length} tasks');
    await _mutex.run(() => _applyTasks(tasks));
  }

  // ── Recovery ───────────────────────────────────────────────────────

  /// Close a visit that was still open at the last shutdown. We cannot
  /// trust that the manager is still inside, so per the recovery contract
  /// the visit is closed at the last in-geofence fix with an estimated
  /// exit. If the manager is in fact still inside, a fresh cycle re-enters
  /// normally. MUST run inside [_mutex].
  Future<void> _recoverOpenVisit() async {
    final ov = await _store.loadOpenVisit();
    if (ov == null) {
      _log.debug('Recovery', 'No open visit to recover');
      return;
    }
    _log.warn(
      'Recovery',
      'Recovered open visit for task=${ov.taskId}, closing with estimated exit',
    );
    _openVisit = ov;
    await _closeVisitLocked(exitFix: ov.lastInsideFix, exitEstimated: true);
  }

  // ── Task coupling ──────────────────────────────────────────────────

  Future<void> _refreshTasks() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await _taskDatasource.fetchInProgressTasks();
      switch (result) {
        case Success(:final data):
          // Only the assignee's own device should detect the visit. ADMIN /
          // MANAGER can see everyone's IN_PROGRESS tasks, but they don't
          // physically visit the shop — arming geofence for someone else's
          // task just burns battery/GPS. Keep only tasks assigned to me.
          final me = await Session.userId();
          final mine = me == null
              ? const <TaskSummary>[]
              : data.where((t) => t.assignee.id == me).toList();
          _log.info(
            'Tasks',
            'Fetched ${data.length} IN_PROGRESS tasks — ${mine.length} assigned to me (userId=$me)',
          );
          await _mutex.run(() => _applyTasks(mine));
        case Failure(:final exception):
          _log.error('Tasks', 'Failed to fetch tasks: $exception');
          break;
      }
    } finally {
      _refreshing = false;
    }
  }

  /// Rebuild targets from IN_PROGRESS tasks, reconcile the open visit
  /// against them, then arm/disarm. MUST run inside [_mutex].
  Future<void> _applyTasks(List<TaskSummary> tasks) async {
    final targets = <GeofenceTarget>[];
    int skippedNoCoords = 0;
    for (final t in tasks) {
      if (t.status != 'IN_PROGRESS') continue;
      // Use the same coord-resolution the route screen uses: prefer the
      // top-level shop_latitude/shop_longitude snapshot (always populated
      // on newer tasks) and fall back to the embedded shop relation.
      final coords = taskShopLatLng(t);
      if (coords == null) {
        skippedNoCoords++;
        continue;
      }
      if (coords.lat < -90 ||
          coords.lat > 90 ||
          coords.lng < -180 ||
          coords.lng > 180)
        continue;
      targets.add(
        GeofenceTarget(
          taskId: t.id,
          shopId: t.shop?.id ?? 0,
          shopName: t.shop?.name ?? t.title,
          latitude: coords.lat,
          longitude: coords.lng,
        ),
      );
    }
    _targets = targets;

    if (skippedNoCoords > 0) {
      _log.warn(
        'Tasks',
        'Skipped $skippedNoCoords tasks with missing/invalid coords',
      );
    }
    for (final tg in targets) {
      _log.info(
        'Tasks',
        'Target: task=${tg.taskId} shop="${tg.shopName}" @ (${tg.latitude.toStringAsFixed(6)}, ${tg.longitude.toStringAsFixed(6)})',
      );
    }

    // Task completed/cancelled (or reassigned) while we were inside its
    // geofence → close & send immediately.
    final ov = _openVisit;
    if (ov != null && !targets.any((tg) => tg.taskId == ov.taskId)) {
      _log.warn(
        'Tasks',
        'Open visit task=${ov.taskId} no longer in targets — closing',
      );
      await _closeVisitLocked(
        exitFix: _lastFix ?? ov.lastInsideFix,
        exitEstimated: true,
      );
    }

    if (_targets.isEmpty && _openVisit == null) {
      _log.info('Tasks', 'No targets → DISARMING');
      await _disarmLocked();
    } else {
      _log.info('Tasks', '${_targets.length} target(s) → ARMING');
      await _armLocked();
    }
  }

  // ── Arm / disarm ───────────────────────────────────────────────────

  Future<void> _armLocked() async {
    if (_positionSub == null) {
      // Detection runs in the background-service isolate, which has no
      // foreground Activity — so only CHECK the permission, never request it
      // (requesting throws "Unable to detect current Activity"). The grant is
      // obtained by the foreground app before the service starts.
      final ok = await LocationTracker.instance.acquire(
        _locationToken,
        requestPermission: false,
      );
      if (!ok) {
        _log.error('Arm', 'Location permission DENIED — staying disarmed');
        _setState(GeofenceState.disarmed);
        return;
      }
      _log.info('Arm', 'Location stream acquired — listening for GPS fixes');
      _positionSub = LocationTracker.instance.stream.listen(
        _onPosition,
        onError: (_) {},
      );
      final last = LocationTracker.instance.lastPosition;
      if (last != null) {
        _log.debug('Arm', 'Evaluating last known position immediately');
        _onPosition(last);
      }
    }
    final newState = _openVisit != null
        ? GeofenceState.inside
        : GeofenceState.armed;
    _log.info('Arm', 'State → $newState');
    _setState(newState);
  }

  Future<void> _disarmLocked() async {
    _log.info('Disarm', 'Releasing location stream — DISARMED');
    await _positionSub?.cancel();
    _positionSub = null;
    await LocationTracker.instance.release(_locationToken);
    _setState(GeofenceState.disarmed);
  }

  // ── Fix processing ─────────────────────────────────────────────────

  void _onPosition(Position p) {
    final fix = _toFix(p);
    unawaited(_mutex.run(() => _processFix(fix)));
  }

  Future<void> _processFix(GeoFix fix) async {
    if (GeofenceGeo.isTeleport(fix, _lastFix)) {
      _log.warn(
        'Fix',
        'DROPPED teleport glitch @ (${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)})',
      );
      return;
    }
    if (!GeofenceGeo.isAccurate(fix)) {
      _log.debug(
        'Fix',
        'DROPPED low-accuracy fix (${fix.accuracyMeters.toStringAsFixed(1)}m > ${GeofenceConfig.maxAccuracyMeters}m)',
      );
      return;
    }
    _lastFix = fix;
    _log.debug(
      'Fix',
      'GPS (${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)}) acc=${fix.accuracyMeters.toStringAsFixed(1)}m',
    );

    if (_openVisit != null) {
      await _handleInside(fix);
    } else {
      await _handleArmed(fix);
    }
  }

  /// ARMED: enter the nearest target within the enter radius.
  Future<void> _handleArmed(GeoFix fix) async {
    if (_targets.isEmpty) return;

    GeofenceTarget? nearest;
    var nearestDistance = double.infinity;
    for (final t in _targets) {
      final d = GeofenceGeo.distanceMeters(
        lat1: fix.latitude,
        lng1: fix.longitude,
        lat2: t.latitude,
        lng2: t.longitude,
      );
      if (d < nearestDistance) {
        nearestDistance = d;
        nearest = t;
      }
    }
    if (nearest == null || nearestDistance > GeofenceConfig.enterRadiusMeters) {
      if (nearest != null) {
        _log.debug(
          'Armed',
          '${nearestDistance.toStringAsFixed(1)}m from "${nearest.shopName}" (enter=${GeofenceConfig.enterRadiusMeters}m) — outside',
        );
      }
      return;
    }

    _log.info(
      'ENTER',
      '🟢 ENTERED geofence of "${nearest.shopName}" (task=${nearest.taskId}) at ${nearestDistance.toStringAsFixed(1)}m',
    );

    final visit = OpenVisit(
      visitId: _generateVisitId(),
      taskId: nearest.taskId,
      shopId: nearest.shopId,
      centerLatitude: nearest.latitude,
      centerLongitude: nearest.longitude,
      enteredAtUtc: fix.timestampUtc,
      enterLatitude: fix.latitude,
      enterLongitude: fix.longitude,
      lastInsideFix: fix,
    );
    _openVisit = visit;
    await _store.saveOpenVisit(visit);
    _insideTaskId = visit.taskId;
    _setState(GeofenceState.inside);

    final cb = onEnter;
    if (cb != null) scheduleMicrotask(() => cb(visit.taskId));
  }

  /// INSIDE: refresh the anchor while inside, accrue exit evidence beyond
  /// the exit radius, and confirm an exit per the hysteresis rules.
  Future<void> _handleInside(GeoFix fix) async {
    final ov = _openVisit;
    if (ov == null) return;

    final distance = GeofenceGeo.distanceMeters(
      lat1: fix.latitude,
      lng1: fix.longitude,
      lat2: ov.centerLatitude,
      lng2: ov.centerLongitude,
    );

    if (distance <= GeofenceConfig.enterRadiusMeters) {
      _log.debug(
        'Inside',
        'Still inside (${distance.toStringAsFixed(1)}m) — anchor updated',
      );
      final updated = ov.copyWith(
        lastInsideFix: fix,
        clearOutsideEvidence: true,
      );
      _openVisit = updated;
      await _store.saveOpenVisit(updated);
      return;
    }

    if (distance < GeofenceConfig.exitRadiusMeters) {
      _log.debug(
        'Inside',
        'In hysteresis band (${distance.toStringAsFixed(1)}m) — holding',
      );
      return;
    }

    // Beyond the exit radius → accumulate exit evidence.
    final firstOutside = ov.firstOutsideAtUtc ?? fix.timestampUtc;
    final consecutive = ov.consecutiveOutsideFixes + 1;
    final sustained =
        fix.timestampUtc.difference(firstOutside) >=
        GeofenceConfig.exitSustainedDuration;

    _log.info(
      'Exit',
      'Outside at ${distance.toStringAsFixed(1)}m — evidence $consecutive/${GeofenceConfig.exitConsecutiveFixes} fixes, sustained=$sustained',
    );

    if (consecutive >= GeofenceConfig.exitConsecutiveFixes || sustained) {
      _log.info('EXIT', '🔴 EXITED geofence of task=${ov.taskId} (confirmed)');
      await _closeVisitLocked(exitFix: fix, exitEstimated: false);
    } else {
      final updated = ov.copyWith(
        consecutiveOutsideFixes: consecutive,
        firstOutsideAtUtc: firstOutside,
      );
      _openVisit = updated;
      await _store.saveOpenVisit(updated);
    }
  }

  /// While INSIDE, if the anchor has gone stale (no recent in-geofence
  /// fix) actively probe the GPS. A returned fix is processed normally; if
  /// location is genuinely unavailable (permission revoked / GPS off) the
  /// visit is closed from the last in-geofence fix with an estimated exit.
  Future<void> _checkStaleVisit() async {
    final ov = _openVisit;
    if (ov == null) return;
    final age = DateTime.now().toUtc().difference(
      ov.lastInsideFix.timestampUtc,
    );
    if (age < GeofenceConfig.staleVisitTimeout) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      pos = null;
    }

    if (pos != null) {
      _onPosition(pos);
    } else {
      await _mutex.run(() async {
        final current = _openVisit;
        if (current == null) return;
        await _closeVisitLocked(
          exitFix: current.lastInsideFix,
          exitEstimated: true,
        );
      });
    }
  }

  // ── Close a visit ──────────────────────────────────────────────────

  /// Build the visit record, persist it to the queue BEFORE forgetting the
  /// open visit (crash-safe), then trigger an async upload. Sub-minimum
  /// stays are discarded as jitter. MUST run inside [_mutex].
  Future<void> _closeVisitLocked({
    required GeoFix exitFix,
    required bool exitEstimated,
  }) async {
    final ov = _openVisit;
    if (ov == null) return;

    final visit = GeofenceVisit(
      visitId: ov.visitId,
      taskId: ov.taskId,
      shopId: ov.shopId,
      enteredAtUtc: ov.enteredAtUtc,
      exitedAtUtc: exitFix.timestampUtc,
      exitEstimated: exitEstimated,
      enterLatitude: ov.enterLatitude,
      enterLongitude: ov.enterLongitude,
      exitLatitude: exitFix.latitude,
      exitLongitude: exitFix.longitude,
    );

    final isValid =
        visit.stayDurationSeconds >= GeofenceConfig.minValidStay.inSeconds;

    _log.info(
      'Close',
      'Visit task=${ov.taskId}: stay=${visit.stayDurationSeconds}s, valid=$isValid, estimated=$exitEstimated',
    );

    if (isValid) await _uploader.persist(visit);

    _openVisit = null;
    await _store.clearOpenVisit();

    _insideTaskId = null;
    if (!exitEstimated) {
      final cb = onRealExit;
      if (cb != null) scheduleMicrotask(() => cb(ov.taskId));
    }

    if (_targets.isEmpty) {
      await _positionSub?.cancel();
      _positionSub = null;
      await LocationTracker.instance.release(_locationToken);
      _setState(GeofenceState.disarmed);
    } else {
      _setState(GeofenceState.armed);
    }

    if (isValid) {
      _log.info(
        'Upload',
        'Visit queued for upload (${visit.stayDurationSeconds}s stay)',
      );
      unawaited(_uploader.flush());
    } else {
      _log.warn(
        'Close',
        'Discarded ${visit.stayDurationSeconds}s jitter visit (min=${GeofenceConfig.minValidStay.inSeconds}s)',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  GeoFix _toFix(Position p) {
    var ts = p.timestamp.toUtc();
    if (ts.year < 2000) ts = DateTime.now().toUtc(); // guard bogus device time
    return GeoFix(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      timestampUtc: ts,
    );
  }

  void _setState(GeofenceState state) {
    if (stateListenable.value != state) stateListenable.value = state;
  }

  /// RFC-4122 v4 UUID from a cryptographically secure RNG — the backend
  /// dedupe key, so it must be unique and stable for a visit's lifetime.
  String _generateVisitId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
