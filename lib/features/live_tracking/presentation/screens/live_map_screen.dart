import 'dart:async';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/features/live_tracking/data/models/live_location.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Live team map.
///
/// - Pulls the `/employees/live` snapshot once, drops a marker per employee
///   whose location is known.
/// - Subscribes to the socket: `employee:location` moves markers,
///   `employee:offline` removes them.
///
/// Pure viewer — this screen never emits its own location. A manager's own
/// field tracking lives on the Routes screen (slide-to-track control).
class LiveMapScreen extends StatefulWidget {
  /// If set, the camera flies to this employee once their position is known.
  final String? focusEmployeeId;
  final String? title;

  const LiveMapScreen({super.key, this.focusEmployeeId, this.title});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _green = Color(0xff0E5A3B);

  MapboxMap? _map;
  CircleAnnotationManager? _circles;

  final _socket = LiveTrackingSocket.instance;

  // employeeId -> annotation / display name
  final Map<String, CircleAnnotation> _markers = {};
  final Map<String, String> _names = {};

  StreamSubscription? _locSub;
  StreamSubscription? _presSub;
  StreamSubscription<SocketStatus>? _statusSub;

  bool _snapshotLoading = true;
  String? _snapshotError;
  SocketStatus _socketStatus = SocketStatus.idle;

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _statusSub = _socket.onStatus.listen((s) {
      if (mounted) setState(() => _socketStatus = s);
    });
    _locSub = _socket.onEmployeeLocation.listen(_onRemoteLocation);
    _presSub = _socket.onEmployeeOnline.listen(_onPresence);
    _socket.connect();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _presSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _circles = await map.annotations.createCircleAnnotationManager();
    await _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _snapshotLoading = true;
      _snapshotError = null;
    });
    try {
      final ds = TeamDataSourceImpl(DioClient.createDio());
      final res = await ds.getLiveEmployees();
      for (final e in res.employees) {
        if (!e.online) continue;
        _names[e.employeeId] = e.employee.fullName;
        final pos = LiveLatLng.tryParse(e.location);
        if (pos != null) {
          await _upsertMarker(e.employeeId, pos);
        }
      }
      if (!mounted) return;
      setState(() => _snapshotLoading = false);
      await _fitOrLocate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _snapshotLoading = false;
        _snapshotError = "Couldn't load the live snapshot";
      });
    }
  }

  Future<void> _fitOrLocate() async {
    if (_markers.isNotEmpty) {
      final first = _markers.values.first.geometry;
      await _map?.flyTo(
        CameraOptions(center: first, zoom: 13.0),
        MapAnimationOptions(duration: 900),
      );
      return;
    }
    // No known positions yet — center on this device.
    try {
      final p = await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(accuracy: geo.LocationAccuracy.medium),
      );
      await _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(p.longitude, p.latitude)),
          zoom: 12.0,
        ),
        MapAnimationOptions(duration: 900),
      );
    } catch (_) {/* keep default camera */}
  }

  Future<void> _upsertMarker(String employeeId, LiveLatLng pos) async {
    final mgr = _circles;
    if (mgr == null) return;
    final point = Point(coordinates: Position(pos.longitude, pos.latitude));

    final existing = _markers[employeeId];
    if (existing != null) {
      existing.geometry = point;
      await mgr.update(existing);
    } else {
      final created = await mgr.create(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: 8.0,
          circleColor: _green.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3.0,
        ),
      );
      _markers[employeeId] = created;
    }

    if (!_focused &&
        widget.focusEmployeeId != null &&
        widget.focusEmployeeId == employeeId) {
      _focused = true;
      await _map?.flyTo(
        CameraOptions(center: point, zoom: 15.0),
        MapAnimationOptions(duration: 900),
      );
    }
  }

  Future<void> _removeMarker(String employeeId) async {
    final m = _markers.remove(employeeId);
    if (m != null) await _circles?.delete(m);
  }

  // ── Socket events ─────────────────────────────────────────────────────────

  void _onRemoteLocation(EmployeeLocationEvent e) {
    _upsertMarker(e.employeeId, e.position);
  }

  void _onPresence(EmployeeOnlineEvent e) {
    if (!e.online) _removeMarker(e.employeeId);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('liveTeamMap'),
            styleUri: MapboxStyles.STANDARD,
            // PERF TEST: SurfaceView (default) renders the map directly instead
            // of copying every frame into a Flutter texture — smoother + less
            // heat/battery. If overlays flicker or z-order breaks, flip back to
            // true. Validated here before rolling out to the other map screens.
            textureView: false,
            onMapCreated: _onMapCreated,
          ),

          // Top bar: back + title + socket status
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
                            widget.title ?? 'Live Team',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111111),
                            ),
                          ),
                        ),
                        _statusDot(),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff667085),
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

          if (_snapshotLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _green,
                backgroundColor: Color(0xffDDF5E0),
              ),
            ),

          if (_snapshotError != null)
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
                        size: 18, color: Color(0xff667085)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _snapshotError!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xff667085)),
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

        ],
      ),
    );
  }

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
      SocketStatus.connected => const Color(0xff22C55E),
      SocketStatus.connecting => Colors.orange,
      SocketStatus.error => Colors.red,
      _ => const Color(0xff667085),
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
