import 'dart:async';

import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/routes/data/mapbox_directions_service.dart';
import 'package:fieldguard/features/live_tracking/data/models/live_location.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:fieldguard/core/theme/app_colors.dart';

/// Live map for one task's assignee (Admin / Manager only).
///
/// Flow: REST snapshot drops the initial pin → `task:watch` joins the
/// server room → `task:location` moves the pin in real time →
/// `task:status_changed` ends the session when the task completes /
/// cancels. `task:unwatch` is emitted on close.
class TaskLiveTrackingScreen extends ConsumerStatefulWidget {
  final int taskId;
  final int? employeeId;
  final String? taskTitle;
  final String? employeeName;

  /// The task's shop coordinates — the assignee's destination. Drawn as a
  /// static pin so the viewer sees where they're heading. Null for tasks
  /// without usable shop coords, in which case only the live pin shows.
  final double? shopLatitude;
  final double? shopLongitude;
  final String? shopName;

  const TaskLiveTrackingScreen({
    super.key,
    required this.taskId,
    this.employeeId,
    this.taskTitle,
    this.employeeName,
    this.shopLatitude,
    this.shopLongitude,
    this.shopName,
  });

  @override
  ConsumerState<TaskLiveTrackingScreen> createState() =>
      _TaskLiveTrackingScreenState();
}

class _TaskLiveTrackingScreenState
    extends ConsumerState<TaskLiveTrackingScreen> {
  static const _green = AppColors.green;
  static const _dest = AppColors.red12;

  final _socket = LiveTrackingSocket.instance;

  MapboxMap? _map;
  CircleAnnotationManager? _circles;
  PolylineAnnotationManager? _lines;
  CircleAnnotation? _pin;
  PolylineAnnotation? _routeLine;

  StreamSubscription<TaskLocationEvent>? _locSub;
  StreamSubscription<TaskStatusChangedEvent>? _statusSub;
  StreamSubscription<SocketStatus>? _sockSub;

  bool _snapshotLoading = true;
  String? _snapshotError;
  bool _watching = false;
  bool _centered = false;

  SocketStatus _socketStatus = SocketStatus.idle;
  String? _employeeName;
  DateTime? _lastFix;

  // Route (current → destination) summary, recomputed as the assignee moves.
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _routeBusy = false;
  // Origin of the last computed route — used to throttle Directions calls so
  // we only recompute after the assignee has moved a meaningful distance.
  double? _routeFromLat;
  double? _routeFromLng;

  /// Set when task:status_changed reports a terminal state — the assignee
  /// is no longer active so we stop following and tell the viewer.
  String? _endedStatus;

  @override
  void initState() {
    super.initState();
    _employeeName = widget.employeeName;
    _sockSub = _socket.onStatus.listen((s) {
      if (mounted) setState(() => _socketStatus = s);
    });
    _locSub = _socket.onTaskLocation.listen(_onTaskLocation);
    _statusSub = _socket.onTaskStatusChanged.listen(_onStatusChanged);
    _socket.connect();
  }

  @override
  void dispose() {
    // Leave the server room first, then drop the local listeners.
    _socket.emitTaskUnwatch(widget.taskId);
    _locSub?.cancel();
    _statusSub?.cancel();
    _sockSub?.cancel();
    super.dispose();
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    // Polyline manager first so the route line renders beneath the pins.
    _lines = await map.annotations.createPolylineAnnotationManager();
    _circles = await map.annotations.createCircleAnnotationManager();
    await _drawDestination();
    await _loadSnapshot();
    // Join the task room regardless of the snapshot result — the socket
    // stream is the source of truth once the assignee starts moving.
    if (!_watching) {
      _socket.emitTaskWatch(widget.taskId);
      _watching = true;
    }
  }

  /// Drop a static red pin at the task's shop (the assignee's destination).
  /// Until the first live fix arrives, frame the map on it so the viewer has
  /// context instead of a blank default view. No-op when the task carries no
  /// usable shop coordinates.
  Future<void> _drawDestination() async {
    final mgr = _circles;
    final lat = widget.shopLatitude;
    final lng = widget.shopLongitude;
    if (mgr == null || lat == null || lng == null) return;

    final point = Point(coordinates: Position(lng, lat));
    // Static pin — drawn once, never updated/removed, so we don't keep the ref.
    await mgr.create(
      CircleAnnotationOptions(
        geometry: point,
        circleRadius: 9.0,
        circleColor: _dest.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ),
    );

    // No live fix yet → center on the destination. The first assignee fix
    // re-centres on them (see [_movePin], which keys off [_centered]).
    if (!_centered) {
      await _map?.flyTo(
        CameraOptions(center: point, zoom: 14.0),
        MapAnimationOptions(duration: 600),
      );
    }
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _snapshotLoading = true;
      _snapshotError = null;
    });

    final result =
        await ref.read(getTaskLiveTrackingUsecaseProvider)(widget.taskId);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        final loc = data.location;
        if (loc != null) {
          await _movePin(LiveLatLng(loc.latitude, loc.longitude),
              recordedAt: loc.recordedAt == null
                  ? null
                  : DateTime.tryParse(loc.recordedAt!));
        }
        setState(() => _snapshotLoading = false);
      case Failure(:final exception):
        setState(() {
          _snapshotLoading = false;
          _snapshotError = exception.toString();
        });
    }
  }

  Future<void> _movePin(LiveLatLng pos, {DateTime? recordedAt}) async {
    final mgr = _circles;
    if (mgr == null) return;
    final point = Point(coordinates: Position(pos.longitude, pos.latitude));

    final existing = _pin;
    if (existing != null) {
      existing.geometry = point;
      await mgr.update(existing);
    } else {
      _pin = await mgr.create(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: 9.0,
          circleColor: _green.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3.0,
        ),
      );
    }

    if (mounted) setState(() => _lastFix = recordedAt ?? _lastFix);

    // Follow the assignee: snap on first fix, then keep them centred.
    await _map?.flyTo(
      CameraOptions(center: point, zoom: _centered ? 16.0 : 15.5),
      MapAnimationOptions(duration: _centered ? 600 : 900),
    );
    _centered = true;

    // Recompute the driving route to the destination (throttled). Fire and
    // forget — pin movement must not wait on the Directions API.
    unawaited(_maybeUpdateRoute(pos));
  }

  /// Recompute the driving route from the assignee's live position to the
  /// shop, then redraw the polyline + refresh the ETA/distance. Throttled so
  /// the Directions API is only hit after the assignee has moved a meaningful
  /// distance. No-op when the task has no destination coordinates.
  Future<void> _maybeUpdateRoute(LiveLatLng from) async {
    final destLat = widget.shopLatitude;
    final destLng = widget.shopLongitude;
    if (destLat == null || destLng == null || _routeBusy) return;

    // Skip if we already routed from within 60 m of here — stops API spam on
    // every fix while the assignee is roughly stationary.
    final lastLat = _routeFromLat;
    final lastLng = _routeFromLng;
    if (lastLat != null && lastLng != null) {
      final moved = geo.Geolocator.distanceBetween(
          lastLat, lastLng, from.latitude, from.longitude);
      if (moved < 60) return;
    }

    _routeBusy = true;
    final route = await MapboxDirectionsService.instance.drivingRoute(
      originLat: from.latitude,
      originLng: from.longitude,
      destLat: destLat,
      destLng: destLng,
    );
    _routeBusy = false;
    if (!mounted || route == null || route.geometry.isEmpty) return;

    _routeFromLat = from.latitude;
    _routeFromLng = from.longitude;
    await _drawRoute(route.geometry);
    setState(() {
      _routeDistanceMeters = route.distanceMeters;
      _routeDurationSeconds = route.durationSeconds;
    });
  }

  /// Draw (or move) the route polyline. Geometry arrives as `[lng, lat]` pairs.
  Future<void> _drawRoute(List<List<double>> geometry) async {
    final mgr = _lines;
    if (mgr == null) return;
    final positions =
        geometry.map((p) => Position(p[0], p[1])).toList(growable: false);

    final existing = _routeLine;
    if (existing != null) {
      existing.geometry = LineString(coordinates: positions);
      await mgr.update(existing);
    } else {
      _routeLine = await mgr.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: _green.toARGB32(),
          lineWidth: 5.0,
          lineOpacity: 0.85,
        ),
      );
    }
  }

  // ── Socket events ─────────────────────────────────────────────────────────

  void _onTaskLocation(TaskLocationEvent e) {
    if (e.taskId != widget.taskId.toString()) return;
    if (e.employeeName != null && e.employeeName!.isNotEmpty) {
      _employeeName = e.employeeName;
    }
    _movePin(e.position, recordedAt: e.recordedAt);
  }

  void _onStatusChanged(TaskStatusChangedEvent e) {
    if (e.taskId != widget.taskId.toString()) return;
    final s = e.status.toUpperCase();
    // Anything other than IN_PROGRESS means the assignee is no longer
    // actively tracked for this task — stop following.
    if (s != 'IN_PROGRESS' && mounted) {
      setState(() => _endedStatus = s);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('taskLiveMap'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          if (_snapshotLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _green,
                backgroundColor: AppColors.green6,
              ),
            ),

          // Top bar: back + task title + socket status.
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _circleBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: _pill,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.taskTitle ?? 'Task #${widget.taskId}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        _statusDot(),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Snapshot error — non-fatal, the socket may still deliver fixes.
          if (_snapshotError != null && _endedStatus == null)
            Positioned(
              top: 104,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: _pill,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 18, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Couldn't load the initial position",
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadSnapshot,
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom info card.
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: _endedStatus != null
                ? _EndedCard(status: _endedStatus!)
                : _LiveInfoCard(
                    name: _employeeName ?? 'Assignee',
                    lastFix: _lastFix,
                    hasFix: _pin != null,
                    destinationName: widget.shopName,
                    routeDistanceMeters: _routeDistanceMeters,
                    routeDurationSeconds: _routeDurationSeconds,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Small shared bits (mirrors LiveMapScreen styling) ─────────────────────

  BoxDecoration get _pill => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _green, size: 20),
      ),
    );
  }

  Widget _statusDot() {
    final color = switch (_socketStatus) {
      SocketStatus.connected => AppColors.green5,
      SocketStatus.connecting => Colors.orange,
      SocketStatus.error => Colors.red,
      _ => AppColors.grey,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _statusLabel() => switch (_socketStatus) {
        SocketStatus.connected => 'Live',
        SocketStatus.connecting => 'Connecting',
        SocketStatus.error => 'Offline',
        SocketStatus.disconnected => 'Reconnecting',
        SocketStatus.idle => 'Idle',
      };
}

class _LiveInfoCard extends StatelessWidget {
  final String name;
  final DateTime? lastFix;
  final bool hasFix;
  final String? destinationName;
  final double? routeDistanceMeters;
  final double? routeDurationSeconds;

  const _LiveInfoCard({
    required this.name,
    required this.lastFix,
    required this.hasFix,
    this.destinationName,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
  });

  bool get _hasRoute =>
      routeDistanceMeters != null && routeDurationSeconds != null;

  static String _fmtDist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  static String _fmtDur(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '~$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }

  String get _subtitle {
    if (!hasFix) return 'Waiting for the first location…';
    if (lastFix == null) return 'Live location';
    final d = DateTime.now().difference(lastFix!);
    if (d.inSeconds < 10) return 'Updated just now';
    if (d.inMinutes < 1) return 'Updated ${d.inSeconds}s ago';
    if (d.inMinutes < 60) return 'Updated ${d.inMinutes}m ago';
    return 'Updated ${d.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.gradientStart],
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.grey),
                ),
                if (destinationName != null &&
                    destinationName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _hasRoute
                            ? Icons.directions_car_rounded
                            : Icons.flag_rounded,
                        size: 13,
                        color: AppColors.red12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _hasRoute
                              ? '${_fmtDist(routeDistanceMeters!)} · '
                                  '${_fmtDur(routeDurationSeconds!)} '
                                  'to $destinationName'
                              : 'To $destinationName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasFix)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green6,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.green),
                  SizedBox(width: 5),
                  Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EndedCard extends StatelessWidget {
  final String status;

  const _EndedCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'COMPLETED';
    final color =
        isCompleted ? AppColors.green : AppColors.red5;
    final label = switch (status) {
      'COMPLETED' => 'Task completed',
      'CANCELLED' => 'Task cancelled',
      'PENDING' => 'Task reopened — tracking stopped',
      _ => 'Tracking stopped',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
