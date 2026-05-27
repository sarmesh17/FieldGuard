import 'dart:async';
import 'dart:convert';

import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
// `hide Size` so Flutter's Size (used by PreferredSize) isn't shadowed by
// mapbox's own Size export.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';

import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/services/location_tracker.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/features/routes/data/mapbox_directions_service.dart';
import 'package:fieldguard/features/routes/presentation/providers/navigate_target_provider.dart';
import 'package:fieldguard/features/routes/presentation/providers/route_tasks_provider.dart';
import 'package:fieldguard/features/routes/presentation/screens/components/schedule_list.dart';
import 'package:fieldguard/features/routes/presentation/screens/components/task_nav_overlay_controller.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_provider.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_state.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_detail_screen.dart';

const _kBrand = Color(0xFF0E5A3B);
const _kBrandSoft = Color(0xFFD1FADF);

/// Lets the embedded Mapbox map win pan/scale gestures against the page's
/// scroll view — without these, a vertical drag scrolls the page instead of
/// panning the map.
final Set<Factory<OneSequenceGestureRecognizer>> _mapGestureRecognizers = {
  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
};

/// A resolved manual destination (ADMIN shop picker) — coordinates + label
/// feeding the GeoJSON route line. The field-agent path uses the richer
/// [TaskNavOverlayController] instead.
class _RouteDest {
  final String key;
  final String name;
  final String? address;
  final double lat;
  final double lng;

  const _RouteDest({
    required this.key,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/// Routes tab — two role-specific experiences over one map:
///
///  * EMPLOYEE / MANAGER (field agents) — a "Today's Route" view: Live
///    Tracking toggle, the active IN_PROGRESS task's shop pin + 20 m geofence
///    circle + driving route (via [TaskNavOverlayController]), a navigating /
///    ARRIVED card, and today's schedule. Managers additionally broadcast
///    their location to the team map while tracking. Geofence visit detection
///    + recording runs separately in `AutoGeofenceService`; arrival here is
///    driven by its enter/exit events (not a local distance check).
///  * ADMIN — picks any shop and follows an in-app route to it. Admins run no
///    tasks, so no geofence/visit; this is pure navigation.
class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen>
    with WidgetsBindingObserver {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapOverlayVisible = true;
  geo.Position? _lastPosition;

  // Role — resolved once from the JWT.
  bool _roleResolved = false;
  bool _isManager = false;
  bool _isAdmin = false;
  bool get _isFieldAgent => !_isAdmin; // employee or manager

  // Field tracking (managers broadcast to the team map).
  final _trackSocket = LiveTrackingSocket.instance;
  final _tracker = LocationTracker.instance;
  bool _tracking = false;
  bool _trackBusy = false;

  // ── Field-agent navigation (employee/manager) ───────────────────────────────
  TaskNavOverlayController? _navOverlay;
  DirectionsRoute? _activeRoute;
  bool _activeRouteFetching = false;
  StreamSubscription<geo.Position>? _positionStream;
  double? _straightLineToShop;

  // ── Admin manual route-to-shop ──────────────────────────────────────────────
  _RouteDest? _destination;
  DirectionsRoute? _route;
  bool _routeLoading = false;
  PointAnnotationManager? _shopAnnotations;
  Timer? _rerouteTimer;
  int? _consumedNavTaskId;
  static const _kRouteSourceId = 'admin_route_source';
  static const _kRouteLayerId = 'admin_route_layer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = (await Session.role())?.toUpperCase();
    if (!mounted) return;
    setState(() {
      _isManager = role == 'MANAGER';
      _isAdmin = role == 'ADMIN';
      _roleResolved = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tracking) {
      _trackSocket.ensureConnected().then((_) {
        if (_tracking) _trackSocket.emitTrackingStart();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rerouteTimer?.cancel();
    _positionStream?.cancel();
    _navOverlay?.dispose();
    if (_tracking) {
      _trackSocket.emitTrackingStop();
      _tracker.stop();
    }
    super.dispose();
  }

  // ── Tracking toggle ───────────────────────────────────────────────────────

  Future<void> _setTracking(bool start) async {
    if (_trackBusy) return;
    setState(() => _trackBusy = true);
    try {
      if (start) {
        final status = await Permission.locationWhenInUse.request();
        if (!status.isGranted) {
          _toast('Location permission is required');
          return;
        }
        // Managers broadcast to the team map; employees just track locally.
        if (_isManager) {
          await _trackSocket.connect();
          final ok = await _tracker.start(onPosition: _onBroadcastPosition);
          if (!ok) {
            _toast('Location unavailable');
            return;
          }
          _trackSocket.emitTrackingStart();
        }
        await _mapboxMap?.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            puckBearingEnabled: true,
            puckBearing: PuckBearing.HEADING,
            layerAbove: _navOverlay?.routeLayerId,
          ),
        );
        if (mounted) setState(() => _tracking = true);
        await _resumeNavigation();
      } else {
        if (_isManager) {
          _trackSocket.emitTrackingStop();
          await _tracker.stop();
        }
        await _suspendNavigation();
        if (mounted) setState(() => _tracking = false);
      }
    } finally {
      if (mounted) setState(() => _trackBusy = false);
    }
  }

  void _onBroadcastPosition(geo.Position p) {
    _trackSocket.emitLocationUpdate(
      latitude: p.latitude,
      longitude: p.longitude,
      speed: p.speed,
      heading: p.heading,
      accuracy: p.accuracy,
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ── Map setup ─────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initMap();
  }

  Future<void> _initMap() async {
    final map = _mapboxMap;
    if (map == null) return;

    if (_isFieldAgent) {
      // Pre-create the overlay (empty Mapbox layers + pin image) so a later
      // task transition has zero first-paint latency. No GPS yet.
      final overlay = TaskNavOverlayController(
        map: map,
        onChanged: (route, fetching) {
          if (!mounted) return;
          setState(() {
            _activeRoute = route;
            _activeRouteFetching = fetching;
          });
        },
      );
      await overlay.init();
      if (!mounted) return;
      _navOverlay = overlay;
      if (_tracking) await _resumeNavigation();
      if (mounted) setState(() => _mapOverlayVisible = false);
      return;
    }

    // Admin: request permission, show puck, fly to location, prep markers.
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _mapOverlayVisible = false);
      return;
    }
    await map.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    _shopAnnotations ??= await map.annotations.createPointAnnotationManager();
    await _autoGoToLocation();
  }

  /// Field-agent: bring up GPS-driven parts — puck, fly-to, position stream,
  /// and draw the active task's route.
  Future<void> _resumeNavigation() async {
    final map = _mapboxMap;
    final overlay = _navOverlay;
    if (map == null || overlay == null) return;

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted || !mounted) return;

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        layerAbove: overlay.routeLayerId,
      ),
    );
    await _autoGoToLocation();
    _startPositionStream();

    final active = ref.read(activeInProgressTaskProvider);
    if (active != null) {
      await overlay.setTask(active, currentPos: _lastPosition);
    }
  }

  Future<void> _suspendNavigation() async {
    await _positionStream?.cancel();
    _positionStream = null;
    await _navOverlay?.clear();
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: false),
    );
    _lastPosition = null;
    if (mounted) {
      setState(() {
        _activeRoute = null;
        _activeRouteFetching = false;
        _straightLineToShop = null;
      });
    }
  }

  Future<void> _autoGoToLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _lastPosition = pos;
      if (mounted) {
        final fly = _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1200),
        );
        setState(() => _mapOverlayVisible = false);
        await fly;
      }
    } catch (_) {
      if (mounted) setState(() => _mapOverlayVisible = false);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _goToMyLocation() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final newStatus = await Permission.locationWhenInUse.request();
      if (!newStatus.isGranted) return;
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    }
    await _autoGoToLocation();
  }

  /// Field-agent live position stream — feeds the overlay's re-route trigger
  /// and the nav-card's live straight-line distance.
  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onAgentPosition);
  }

  void _onAgentPosition(geo.Position current) {
    _lastPosition = current;
    _navOverlay?.onPositionUpdate(current);

    final task = ref.read(activeInProgressTaskProvider);
    final c = task == null ? null : taskShopLatLng(task);
    final dist = c != null
        ? geo.Geolocator.distanceBetween(
            current.latitude, current.longitude, c.lat, c.lng)
        : null;
    if (dist != _straightLineToShop && mounted) {
      setState(() => _straightLineToShop = dist);
    }
  }

  // ── Admin manual route-to-shop ──────────────────────────────────────────────

  Future<geo.Position?> _currentPosition() async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _lastPosition = pos;
      return pos;
    } catch (_) {
      return _lastPosition;
    }
  }

  Future<void> _selectDestination(ShopWithCreator picked) async {
    final lat = double.tryParse(picked.shop.latitude);
    final lng = double.tryParse(picked.shop.longitude);
    if (lat == null || lng == null) {
      _toast('This shop has no saved location');
      return;
    }
    await _setDestination(_RouteDest(
      key: 'shop-${picked.shop.id}',
      name: picked.shop.name,
      address: picked.shop.address,
      lat: lat,
      lng: lng,
    ));
  }

  Future<void> _setDestination(_RouteDest dest) async {
    setState(() {
      _destination = dest;
      _routeLoading = true;
      _route = null;
    });
    await _drawShopMarker(dest.lat, dest.lng);
    await _computeRoute(fit: true);
    _startReroute();
  }

  Future<void> _clearDestination() async {
    _rerouteTimer?.cancel();
    _rerouteTimer = null;
    _consumedNavTaskId = null;
    await _shopAnnotations?.deleteAll();
    await _removeRouteLayer();
    if (mounted) {
      setState(() {
        _destination = null;
        _route = null;
        _routeLoading = false;
      });
    }
  }

  void _startReroute() {
    _rerouteTimer?.cancel();
    _rerouteTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _computeRoute(fit: false),
    );
  }

  Future<void> _computeRoute({required bool fit}) async {
    final dest = _destination;
    if (dest == null) return;

    final pos = await _currentPosition();
    if (pos == null) {
      if (mounted) setState(() => _routeLoading = false);
      _toast('Could not get your location for the route');
      return;
    }

    final route = await MapboxDirectionsService.instance.drivingRoute(
      originLat: pos.latitude,
      originLng: pos.longitude,
      destLat: dest.lat,
      destLng: dest.lng,
    );

    if (!mounted || _destination?.key != dest.key) return;

    setState(() {
      _route = route;
      _routeLoading = false;
    });

    if (route != null && route.geometry.isNotEmpty) {
      await _drawRoute(route.geometry);
      if (fit) await _fitToRoute(route.geometry);
    }
  }

  Future<void> _drawShopMarker(double lat, double lng) async {
    final mgr = _shopAnnotations;
    if (mgr == null) return;
    await mgr.deleteAll();
    await mgr.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconSize: 1.6,
        symbolSortKey: 10,
        textField: _destination?.name,
        textOffset: [0, 1.6],
        textSize: 12,
        textColor: 0xFF0E5A3B,
      ),
    );
  }

  Future<void> _drawRoute(List<List<double>> lngLat) async {
    final map = _mapboxMap;
    if (map == null) return;
    final geoJson = jsonEncode({
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': lngLat},
    });
    await _removeRouteLayer();
    await map.style.addSource(GeoJsonSource(id: _kRouteSourceId, data: geoJson));
    await map.style.addLayer(
      LineLayer(
        id: _kRouteLayerId,
        sourceId: _kRouteSourceId,
        lineColor: 0xFF0E5A3B,
        lineWidth: 5.0,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
  }

  Future<void> _removeRouteLayer() async {
    final map = _mapboxMap;
    if (map == null) return;
    try {
      if (await map.style.styleLayerExists(_kRouteLayerId)) {
        await map.style.removeStyleLayer(_kRouteLayerId);
      }
      if (await map.style.styleSourceExists(_kRouteSourceId)) {
        await map.style.removeStyleSource(_kRouteSourceId);
      }
    } catch (_) {}
  }

  Future<void> _fitToRoute(List<List<double>> lngLat) async {
    final map = _mapboxMap;
    if (map == null || lngLat.isEmpty) return;
    var minLng = lngLat.first[0], maxLng = lngLat.first[0];
    var minLat = lngLat.first[1], maxLat = lngLat.first[1];
    for (final c in lngLat) {
      minLng = c[0] < minLng ? c[0] : minLng;
      maxLng = c[0] > maxLng ? c[0] : maxLng;
      minLat = c[1] < minLat ? c[1] : minLat;
      maxLat = c[1] > maxLat ? c[1] : maxLat;
    }
    try {
      final cam = await map.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLng, minLat)),
          northeast: Point(coordinates: Position(maxLng, maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(top: 80, left: 60, bottom: 220, right: 60),
        null,
        null,
        null,
        null,
      );
      await map.flyTo(cam, MapAnimationOptions(duration: 900));
    } catch (_) {}
  }

  Future<void> _openShopPicker() async {
    final state = ref.read(shopsNotifierProvider);
    final shops = state is ShopsSuccess ? state.shops : <ShopWithCreator>[];
    final picked = await showModalBottomSheet<ShopWithCreator>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopPickerSheet(shops: shops),
    );
    if (picked != null) await _selectDestination(picked);
  }

  void _consumeNavigateTarget(NavigateTarget? target) {
    if (target == null || target.taskId == _consumedNavTaskId) return;
    _consumedNavTaskId = target.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigateTargetProvider.notifier).state = null;
      _setDestination(_RouteDest(
        key: 'task-${target.taskId}',
        name: target.shopName,
        address: target.address,
        lat: target.lat,
        lng: target.lng,
      ));
    });
  }

  /// Field-agent counterpart: the destination is derived from
  /// [activeInProgressTaskProvider] (not the manual picker), so all we have
  /// to do is force-refresh the task source — the active-task listener will
  /// then swap the overlay to the right task. Shares [_consumedNavTaskId] so a
  /// single tap can't fire both consumers.
  void _consumeFieldAgentNavigate(NavigateTarget? target) {
    if (target == null || target.taskId == _consumedNavTaskId) return;
    _consumedNavTaskId = target.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigateTargetProvider.notifier).state = null;
      ref.read(routeTasksProvider.notifier).refresh();
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_roleResolved) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAF9),
        body: Center(
          child: CircularProgressIndicator(color: _kBrand),
        ),
      );
    }
    return _isAdmin ? _buildAdmin(context) : _buildFieldAgent(context);
  }

  // ── Field-agent view (employee / manager) ───────────────────────────────────

  Widget _buildFieldAgent(BuildContext context) {
    // Keep the route screen's own task source + geofence bridge alive.
    ref.watch(routeTasksProvider);
    ref.watch(geofenceEventBridgeProvider);

    // A task's "Navigate" button just pushed us here — the route tasks cache
    // may be stale (the user just flipped a task's status in task detail and
    // we don't reliably get a socket bounce for our own writes). Force-refresh
    // so activeInProgressTaskProvider re-derives against the latest list, then
    // drop the marker so it doesn't refire on the next rebuild.
    _consumeFieldAgentNavigate(ref.watch(navigateTargetProvider));

    // Active task changed → swap the overlay's pin/route.
    ref.listen<TaskSummary?>(activeInProgressTaskProvider, (prev, next) {
      if (prev?.id == next?.id) return;
      _navOverlay?.setTask(next, currentPos: _lastPosition);
    });

    // Arrival (geofence ENTER) → tell the overlay to drop the route line.
    ref.listen<int?>(reachedDestinationTaskIdProvider, (prev, next) {
      final activeId = ref.read(activeInProgressTaskProvider)?.id;
      if (next != null && next == activeId) {
        _navOverlay?.setReached(true);
      }
    });

    final activeTask = ref.watch(activeInProgressTaskProvider);
    final todayCount = ref.watch(todayTaskCountProvider);
    final reachedId = ref.watch(reachedDestinationTaskIdProvider);
    final hasReached = activeTask != null && reachedId == activeTask.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Today's Route",
          style: TextStyle(
            color: _kBrand,
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.scaledFontSize(20),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _kBrandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                todayCount == 1 ? '1 Task' : '$todayCount Tasks',
                style: TextStyle(
                  color: _kBrand,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.scaledFontSize(14),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: _TrackingToggleBar(
            active: _tracking,
            busy: _trackBusy,
            onToggle: () => _setTracking(!_tracking),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMap(showMyLocation: _tracking, showFullscreen: _tracking),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _ActiveNavCard(
                task: activeTask,
                route: _activeRoute,
                routeFetching: _activeRouteFetching,
                reached: hasReached,
                straightLineMeters: _straightLineToShop,
                onOpenTask: activeTask == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TaskDetailScreen(taskId: activeTask.id),
                          ),
                        ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
            const ScheduleList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Admin view (manual picker) ──────────────────────────────────────────────

  Widget _buildAdmin(BuildContext context) {
    ref.watch(shopsNotifierProvider); // keep shop list warm for the picker
    _consumeNavigateTarget(ref.watch(navigateTargetProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Shop Route',
          style: TextStyle(
            color: const Color(0xff111111),
            fontWeight: FontWeight.w700,
            fontSize: SizeConfig.scaledFontSize(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMap(showMyLocation: true, showFullscreen: true),
            if (_isAdmin || _destination != null) _buildAdminDestinationCard(),
          ],
        ),
      ),
    );
  }

  // ── Shared map ──────────────────────────────────────────────────────────────

  Widget _buildMap({required bool showMyLocation, required bool showFullscreen}) {
    final mapHeight = SizeConfig.heightPercent(35).clamp(200.0, 300.0);
    final trackingCurtain = _isFieldAgent && !_tracking;

    return SizedBox(
      width: double.infinity,
      height: mapHeight + 24,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: mapHeight,
                child: Stack(
                  children: [
                    MapWidget(
                      key: const ValueKey('routeMap'),
                      styleUri: MapboxStyles.STANDARD,
                      textureView: true,
                      onMapCreated: _onMapCreated,
                      // Claim pan/scale gestures from the surrounding
                      // SingleChildScrollView so the embedded map can be
                      // dragged/zoomed instead of scrolling the page.
                      gestureRecognizers: _mapGestureRecognizers,
                    ),
                    if ((_isLocating || _routeLoading) && !_mapOverlayVisible)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: _kBrand,
                          backgroundColor: _kBrandSoft,
                        ),
                      ),
                    if (trackingCurtain)
                      const Positioned.fill(child: _TrackingOffOverlay()),
                    AnimatedOpacity(
                      opacity: _mapOverlayVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      child: _mapOverlayVisible
                          ? const _MapLoadingOverlay()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showFullscreen)
            Positioned(
              top: 24,
              right: 24,
              child: _MapIconButton(icon: Icons.fullscreen, onTap: _openFullscreen),
            ),
          if (showMyLocation)
            Positioned(
              bottom: 8,
              right: 24,
              child: _MapIconButton(
                  icon: Icons.my_location, onTap: _goToMyLocation),
            ),
        ],
      ),
    );
  }

  void _openFullscreen() {
    // Field agents see the active task's pin + geofence + route in fullscreen
    // too; admins (and agents with no active task) get a plain map.
    final active =
        _isFieldAgent ? ref.read(activeInProgressTaskProvider) : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MapFullscreenScreen(
          initialLat: _lastPosition?.latitude,
          initialLng: _lastPosition?.longitude,
          task: active,
        ),
      ),
    );
  }

  // ── Admin destination card ──────────────────────────────────────────────────

  Widget _buildAdminDestinationCard() {
    final dest = _destination;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: dest == null ? _buildPickPrompt() : _buildDestinationDetails(dest),
    );
  }

  Widget _buildPickPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DESTINATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff667085),
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 8),
        const Text('Pick a shop to see the route',
            style: TextStyle(fontSize: 16, color: Color(0xff667085))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openShopPicker,
            icon: const Icon(Icons.storefront_outlined, size: 20),
            label: const Text('Choose Shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationDetails(_RouteDest dest) {
    final route = _route;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('DESTINATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff667085),
                  letterSpacing: 0.5,
                )),
            const Spacer(),
            GestureDetector(
              onTap: _clearDestination,
              child: const Icon(Icons.close, size: 20, color: Color(0xff667085)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(dest.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xff111111),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: Color(0xff667085)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(dest.address ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xff667085))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_routeLoading)
          Row(
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kBrand),
              ),
              SizedBox(width: 8),
              Text('Calculating route…',
                  style: TextStyle(fontSize: 14, color: Color(0xff667085))),
            ],
          )
        else if (route != null)
          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: _kBrand),
              const SizedBox(width: 4),
              Text(_formatDistance(route.distanceMeters),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kBrand,
                  )),
              const SizedBox(width: 8),
              Text(_formatDuration(route.durationSeconds),
                  style: const TextStyle(fontSize: 14, color: Color(0xff667085))),
            ],
          )
        else
          const Text('Route unavailable — check your connection.',
              style: TextStyle(fontSize: 13, color: Color(0xffC0392B))),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isAdmin ? _openShopPicker : _clearDestination,
            icon: Icon(_isAdmin ? Icons.swap_horiz : Icons.close, size: 20),
            label: Text(_isAdmin ? 'Change Shop' : 'Clear Route'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBrand,
              side: const BorderSide(color: _kBrand),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '~$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }
}

// ── Tracking toggle bar ─────────────────────────────────────────────────────────

class _TrackingToggleBar extends StatelessWidget {
  final bool active;
  final bool busy;
  final VoidCallback onToggle;

  const _TrackingToggleBar({
    required this.active,
    required this.busy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kBrandSoft : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? _kBrand : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.location_on : Icons.location_off,
              color: active ? _kBrand : const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Tracking',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      )),
                  Text(
                    active ? 'Tracking your location' : 'Tracking is off',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: _kBrand),
              )
            else
              Switch(
                value: active,
                activeThumbColor: _kBrand,
                onChanged: (_) => onToggle(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackingOffOverlay extends StatelessWidget {
  const _TrackingOffOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.white.withValues(alpha: 0.78),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, color: Color(0xFF6B7280), size: 34),
            SizedBox(height: 8),
            Text('Live Tracking is off',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF111827),
                )),
            SizedBox(height: 2),
            Text('Enable it above to see your route.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

// ── Active navigation card ──────────────────────────────────────────────────────

class _ActiveNavCard extends StatelessWidget {
  final TaskSummary? task;
  final DirectionsRoute? route;
  final bool routeFetching;
  final bool reached;
  final double? straightLineMeters;
  final VoidCallback? onOpenTask;

  const _ActiveNavCard({
    required this.task,
    required this.route,
    required this.routeFetching,
    required this.reached,
    required this.straightLineMeters,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              child: Divider(thickness: 3, color: Color(0xFFE5E7EB)),
            ),
          ),
          const SizedBox(height: 12),
          if (task == null) _empty(context) else _active(context, task!),
        ],
      ),
    );
  }

  Widget _active(BuildContext context, TaskSummary task) {
    final shopName = task.shop?.name ?? task.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(reached ? Icons.check_circle : Icons.circle,
                size: reached ? 14 : 8, color: _kBrand),
            const SizedBox(width: 6),
            Text(
              reached ? 'ARRIVED' : 'NAVIGATING TO',
              style: const TextStyle(
                color: _kBrand,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    reached ? 'You reached your destination' : task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: reached ? _kBrand : const Color(0xFF6B7280),
                      fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (reached)
              const _ArrivedPill()
            else
              _EtaPill(
                route: route,
                fetching: routeFetching,
                straightLineMeters: straightLineMeters,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onOpenTask,
                icon: const Icon(Icons.assignment_outlined, color: Colors.white),
                label: const Text('Open Task',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kBrand),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // Shop phone isn't on the task summary payload yet.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shop phone number not available.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, color: _kBrand),
                label: const Text('Call Shop',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kBrand)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('NO ACTIVE TASK',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            )),
        SizedBox(height: 8),
        Text('Showing your current location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
          'Start a task to see the route to its shop here.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _ArrivedPill extends StatelessWidget {
  const _ArrivedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kBrand,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text('Arrived',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _EtaPill extends StatelessWidget {
  final DirectionsRoute? route;
  final bool fetching;
  final double? straightLineMeters;

  const _EtaPill({
    required this.route,
    required this.fetching,
    required this.straightLineMeters,
  });

  String _label() {
    final m = straightLineMeters;
    if (m != null) {
      final dist =
          m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
      if (route != null && m > 50) {
        return '$dist · ${_dur(route!.durationSeconds)}';
      }
      return '$dist away';
    }
    if (route != null) {
      return '${_dist(route!.distanceMeters)} · ${_dur(route!.durationSeconds)}';
    }
    return fetching ? 'Calculating…' : '— · —';
  }

  static String _dist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  static String _dur(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '~$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h h' : '~$h h $m min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kBrandSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fetching && straightLineMeters == null)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBrand),
            )
          else
            const Icon(Icons.directions_car, size: 16, color: _kBrand),
          const SizedBox(width: 6),
          Text(_label(),
              style: const TextStyle(
                color: _kBrand,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

// ── Admin shop picker sheet ─────────────────────────────────────────────────────

class _ShopPickerSheet extends StatefulWidget {
  final List<ShopWithCreator> shops;

  const _ShopPickerSheet({required this.shops});

  @override
  State<_ShopPickerSheet> createState() => _ShopPickerSheetState();
}

class _ShopPickerSheetState extends State<_ShopPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.shops
        : widget.shops
            .where((s) =>
                s.shop.name.toLowerCase().contains(q) ||
                s.shop.address.toLowerCase().contains(q))
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + kb),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffE0E4EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select a Shop',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff111111))),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search shops…',
              prefixIcon: const Icon(Icons.search, color: Color(0xff9CA3AF)),
              filled: true,
              fillColor: const Color(0xffF2F4F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No shops found',
                    style: TextStyle(color: Color(0xff667085))),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xffF0F2F5)),
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  final hasCoords =
                      double.tryParse(s.shop.latitude) != null &&
                          double.tryParse(s.shop.longitude) != null;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kBrandSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: _kBrand, size: 22),
                    ),
                    title: Text(s.shop.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xff111111))),
                    subtitle: Text(s.shop.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff667085))),
                    trailing: hasCoords
                        ? const Icon(Icons.chevron_right, color: Color(0xff667085))
                        : const Tooltip(
                            message: 'No saved location',
                            child: Icon(Icons.location_off_outlined,
                                color: Color(0xffC0392B), size: 18),
                          ),
                    enabled: hasCoords,
                    onTap: hasCoords ? () => Navigator.of(context).pop(s) : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Map loading overlay ────────────────────────────────────────────────────────

class _MapLoadingOverlay extends StatefulWidget {
  const _MapLoadingOverlay();

  @override
  State<_MapLoadingOverlay> createState() => _MapLoadingOverlayState();
}

class _MapLoadingOverlayState extends State<_MapLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = (_controller.value + index / 3.0) % 1.0;
        return Opacity(
          opacity: ((1.0 - phase) * 0.55).clamp(0.0, 1.0),
          child: Container(
            width: 32 + phase * 58,
            height: 32 + phase * 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kBrand, width: 1.5),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _ring(2),
                  _ring(1),
                  _ring(0),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kBrand,
                      boxShadow: [
                        BoxShadow(
                          color: _kBrand.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AnimatedDotsText(
              base: 'Getting your location',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff667085),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDotsText extends StatefulWidget {
  final String base;
  final TextStyle style;

  const _AnimatedDotsText({required this.base, required this.style});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dots = '.' * ((_controller.value * 3).floor() + 1);
        return Text('${widget.base}$dots', style: widget.style);
      },
    );
  }
}

// ── Fullscreen map ──────────────────────────────────────────────────────────────

class _MapFullscreenScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  /// When set (field agent with an active task), the fullscreen map draws the
  /// same pin + geofence circle + driving route as the embedded map.
  final TaskSummary? task;

  const _MapFullscreenScreen({this.initialLat, this.initialLng, this.task});

  @override
  State<_MapFullscreenScreen> createState() => _MapFullscreenScreenState();
}

class _MapFullscreenScreenState extends State<_MapFullscreenScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapOverlayVisible = true;

  TaskNavOverlayController? _navOverlay;
  StreamSubscription<geo.Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _navOverlay?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initMap();
  }

  Future<void> _initMap() async {
    final map = _mapboxMap;
    if (map == null) return;

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _mapOverlayVisible = false);
      return;
    }

    // Spin up the same overlay the embedded map uses, so the pin/geofence/
    // route render identically here.
    final overlay = TaskNavOverlayController(map: map, onChanged: (_, _) {});
    await overlay.init();
    if (!mounted) return;
    _navOverlay = overlay;

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        layerAbove: overlay.routeLayerId,
      ),
    );

    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      await map.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
        ),
      );
      if (mounted) setState(() => _mapOverlayVisible = false);
    } else {
      await _autoGoToLocation();
    }

    // Draw the active task's route + start the live re-route stream.
    final task = widget.task;
    if (task != null) {
      // Use the origin passed in from the embedded map (likely a few seconds
      // stale at worst) to fire setTask immediately — drawing the pin +
      // geofence + an initial route without waiting on a fresh GPS fix. The
      // position stream below corrects the route as the user moves.
      geo.Position? pos;
      final lat = widget.initialLat;
      final lng = widget.initialLng;
      if (lat != null && lng != null) {
        pos = geo.Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        try {
          pos = await geo.Geolocator.getCurrentPosition(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high,
            ),
          );
        } catch (_) {
          pos = null;
        }
      }
      await overlay.setTask(task, currentPos: pos);
      _startPositionStream();
    }
  }

  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) => _navOverlay?.onPositionUpdate(pos));
  }

  Future<void> _autoGoToLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      if (mounted) {
        final fly = _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1200),
        );
        setState(() => _mapOverlayVisible = false);
        await fly;
      }
    } catch (_) {
      if (mounted) setState(() => _mapOverlayVisible = false);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _goToMyLocation() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final newStatus = await Permission.locationWhenInUse.request();
      if (!newStatus.isGranted) return;
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    }
    await _autoGoToLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('routeMapFullscreen'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
            gestureRecognizers: _mapGestureRecognizers,
          ),
          if (_isLocating && !_mapOverlayVisible)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _kBrand,
                backgroundColor: _kBrandSoft,
              ),
            ),
          AnimatedOpacity(
            opacity: _mapOverlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: _mapOverlayVisible
                ? const _MapLoadingOverlay()
                : const SizedBox.shrink(),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: _MapIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 48,
            right: 16,
            child: _MapIconButton(
              icon: Icons.my_location,
              onTap: _goToMyLocation,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _kBrand, size: 20),
      ),
    );
  }
}
