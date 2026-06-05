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

import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/features/live_tracking/presentation/tracking_controller.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
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
import 'package:fieldguard/core/theme/app_colors.dart';

part 'routes_screen_overlays.dart';
part 'routes_screen_sheets.dart';

const _kBrand = AppColors.green;
const _kBrandSoft = AppColors.green6;
// Header gradient stops — consistent with Team / Profile / Login.
const _kDark = AppColors.green;
const _kMid = AppColors.green;

// Width-based [SizeConfig.scale] balloons on landscape phones. These helpers
// scale off the SHORTER screen side so paddings/fonts stay phone-sized in
// both orientations (matches the helper in Team Management).
double _s(double v) {
  final w = SizeConfig.screenWidth;
  final h = SizeConfig.screenHeight;
  final shorter = w < h ? w : h;
  return v * (shorter / 375);
}

double _sf(double v) {
  final scaled = _s(v);
  return scaled * SizeConfig.textScaleFactor.clamp(0.8, 1.3);
}

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

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapOverlayVisible = true;
  geo.Position? _lastPosition;

  // Role — resolved once from the JWT.
  bool _roleResolved = false;
  bool _isAdmin = false;
  bool get _isFieldAgent => !_isAdmin; // employee or manager

  // Live tracking now lives in [trackingControllerProvider] (shared app-wide,
  // toggled from the Home screen). This screen only reacts to its on/off state
  // to drive the map puck + navigation overlay.

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
  /// Position the currently-drawn route was computed from. The reroute tick
  /// recomputes only once the agent has moved [_rerouteMinMoveMeters] from
  /// here — so a stationary agent never triggers a Directions API call.
  geo.Position? _lastRouteOrigin;
  static const double _rerouteMinMoveMeters = 30;
  static const _kRouteSourceId = 'admin_route_source';
  static const _kRouteLayerId = 'admin_route_layer';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = (await Session.role())?.toUpperCase();
    if (!mounted) return;
    setState(() {
      _isAdmin = role == 'ADMIN';
      _roleResolved = true;
    });
  }

  @override
  void dispose() {
    _rerouteTimer?.cancel();
    _positionStream?.cancel();
    _navOverlay?.dispose();
    super.dispose();
  }

  /// Drive the map puck + navigation overlay off the shared tracking state.
  /// Called from a [ref.listen] when the Home-screen toggle flips, and from
  /// [_initMap] when the screen opens while tracking is already on.
  Future<void> _applyTracking(bool active) async {
    if (!_isFieldAgent) return;
    if (active) {
      await _resumeNavigation();
    } else {
      await _suspendNavigation();
    }
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
      if (ref.read(trackingControllerProvider).active) {
        await _resumeNavigation();
      }
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
            current.latitude,
            current.longitude,
            c.lat,
            c.lng,
          )
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
    await _setDestination(
      _RouteDest(
        key: 'shop-${picked.shop.id}',
        name: picked.shop.name,
        address: picked.shop.address,
        lat: lat,
        lng: lng,
      ),
    );
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
    _lastRouteOrigin = null;
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
      (_) => _rerouteTick(),
    );
  }

  /// Reroute backstop: recompute only when the agent has actually moved far
  /// enough to matter. Uses the live [_lastPosition] (already kept fresh by the
  /// position stream) so the check itself costs no extra GPS fix — the
  /// Directions API is hit only when [_rerouteMinMoveMeters] has been covered.
  void _rerouteTick() {
    if (_destination == null) return;
    final now = _lastPosition;
    final origin = _lastRouteOrigin;
    // No anchor yet (or no fix) → compute once to establish the route.
    if (now == null || origin == null) {
      _computeRoute(fit: false);
      return;
    }
    final moved = geo.Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      now.latitude,
      now.longitude,
    );
    if (moved >= _rerouteMinMoveMeters) {
      _computeRoute(fit: false);
    }
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
      // Anchor the reroute gate to where this route was computed from. Left
      // unchanged on failure so the next tick retries instead of waiting for
      // another 30 m of movement.
      _lastRouteOrigin = pos;
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
    await map.style.addSource(
      GeoJsonSource(id: _kRouteSourceId, data: geoJson),
    );
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
      _setDestination(
        _RouteDest(
          key: 'task-${target.taskId}',
          name: target.shopName,
          address: target.address,
          lat: target.lat,
          lng: target.lng,
        ),
      );
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
        backgroundColor: AppColors.white,
        body: SkeletonList(),
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

    // Live tracking is toggled from the Home screen now — react to it here to
    // show/hide the puck + navigation overlay on the route map.
    ref.listen<TrackingState>(trackingControllerProvider, (prev, next) {
      if ((prev?.active ?? false) != next.active) {
        _applyTracking(next.active);
      }
    });

    final tracking = ref.watch(trackingControllerProvider).active;
    final activeTask = ref.watch(activeInProgressTaskProvider);
    final todayCount = ref.watch(todayTaskCountProvider);
    final reachedId = ref.watch(reachedDestinationTaskIdProvider);
    final hasReached = activeTask != null && reachedId == activeTask.id;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildRoutesHeader(
              title: "Today's Route",
              chipLabel: todayCount == 1 ? '1 Task' : '$todayCount Tasks',
              showChip: true,
            ),
            _buildMap(
              showMyLocation: tracking,
              showFullscreen: tracking,
              isTracking: tracking,
            ),
            _AnimatedEntry(
              index: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _s(16),
                  vertical: _s(16),
                ),
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
            ),
            _AnimatedEntry(
              index: 1,
              child: Padding(
                padding: EdgeInsets.fromLTRB(_s(16), _s(8), _s(16), _s(8)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Today's Schedule",
                    style: TextStyle(
                      fontSize: _sf(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
            const ScheduleList(),
            SizedBox(height: _s(24)),
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
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoutesHeader(title: 'Shop Route', showChip: false),
            _buildMap(showMyLocation: true, showFullscreen: true),
            if (_isAdmin || _destination != null)
              _AnimatedEntry(index: 0, child: _buildAdminDestinationCard()),
          ],
        ),
      ),
    );
  }

  // ─── Shared gradient header (matches Team Management / Profile) ──────────
  Widget _buildRoutesHeader({
    required String title,
    String? chipLabel,
    bool showChip = false,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kDark, _kBrand, _kMid],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative orbs for depth.
          Positioned(
            top: -30,
            right: -20,
            child: _orb(_s(isLandscape ? 90 : 130), 0.07),
          ),
          Positioned(
            bottom: -10,
            left: -30,
            child: _orb(_s(isLandscape ? 60 : 80), 0.05),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _s(16),
                _s(isLandscape ? 2 : 6),
                _s(16),
                _s(isLandscape ? 10 : 16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _sf(isLandscape ? 17 : 19),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (showChip && chipLabel != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _s(12),
                        vertical: _s(5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(_s(20)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _sf(12),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // ── Shared map ──────────────────────────────────────────────────────────────

  Widget _buildMap({
    required bool showMyLocation,
    required bool showFullscreen,
    bool isTracking = true,
  }) {
    final mapHeight = SizeConfig.heightPercent(35).clamp(200.0, 300.0);
    final trackingCurtain = _isFieldAgent && !isTracking;

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
              child: _MapIconButton(
                icon: Icons.fullscreen,
                onTap: _openFullscreen,
              ),
            ),
          if (showMyLocation)
            Positioned(
              bottom: 8,
              right: 24,
              child: _MapIconButton(
                icon: Icons.my_location,
                onTap: _goToMyLocation,
              ),
            ),
        ],
      ),
    );
  }

  void _openFullscreen() {
    // Field agents see the active task's pin + geofence + route in fullscreen
    // too; admins (and agents with no active task) get a plain map.
    final active = _isFieldAgent
        ? ref.read(activeInProgressTaskProvider)
        : null;
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
        const Text(
          'DESTINATION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a shop to see the route',
          style: TextStyle(fontSize: 16, color: AppColors.grey),
        ),
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
                borderRadius: BorderRadius.circular(12),
              ),
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
            const Text(
              'DESTINATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _clearDestination,
              child: const Icon(
                Icons.close,
                size: 20,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          dest.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.grey,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                dest.address ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kBrand,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Calculating route…',
                style: TextStyle(fontSize: 14, color: AppColors.grey),
              ),
            ],
          )
        else if (route != null)
          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: _kBrand),
              const SizedBox(width: 4),
              Text(
                _formatDistance(route.distanceMeters),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kBrand,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(route.durationSeconds),
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
            ],
          )
        else
          const Text(
            'Route unavailable — check your connection.',
            style: TextStyle(fontSize: 13, color: AppColors.red),
          ),
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
                borderRadius: BorderRadius.circular(12),
              ),
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

