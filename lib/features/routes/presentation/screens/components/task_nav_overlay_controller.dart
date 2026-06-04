import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'package:fieldguard/features/auto_geofence/config/geofence_config.dart';
import 'package:fieldguard/features/auto_geofence/service/auto_geofence_service.dart';
import 'package:fieldguard/features/routes/data/mapbox_directions_service.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Re-route only when the user has drifted at least this far from the origin
/// of the previous Directions request — stops API spam every metre.
const _reRouteDistanceMeters = 75.0;

/// Or, regardless of distance, after this much wall-clock time (catches the
/// "stuck in traffic, polyline reflects the old plan" case).
const _reRouteMaxAge = Duration(seconds: 20);

const _kBrand = AppColors.green;

/// Encapsulates the destination pin + geofence circle + driving polyline +
/// camera-fit logic for "navigating to a task". Lives outside the widget tree
/// so the embedded and fullscreen maps can share identical behaviour.
///
/// Lifecycle: construct after [MapboxMap] is ready → [init] once → [setTask]
/// on the active task changing → pipe every [geo.Position] into
/// [onPositionUpdate] → [dispose].
class TaskNavOverlayController {
  final MapboxMap map;

  /// Fired whenever the route or fetching state changes so the host can
  /// refresh the ETA pill / "calculating…" indicator.
  final void Function(DirectionsRoute? route, bool fetching) onChanged;

  PolylineAnnotationManager? _polyManager;
  PointAnnotationManager? _pointManager;
  PolygonAnnotationManager? _polygonManager;
  Uint8List? _pinImage;

  PolylineAnnotation? _routeLine;
  PointAnnotation? _shopPin;
  PolygonAnnotation? _geofence;

  /// Full geometry of the last fetched route in `[lng, lat]` order — kept so
  /// the polyline can be re-anchored to the user's live position each fix
  /// without re-hitting the Directions API.
  List<List<double>>? _routeCoordinates;

  TaskSummary? _currentTask;
  geo.Position? _lastRoutedFrom;
  DateTime _lastRouteAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;
  bool _arrived = false;
  bool _disposed = false;

  TaskNavOverlayController({required this.map, required this.onChanged});

  /// Layer id of the route polyline — host passes this as
  /// `LocationComponentSettings.layerAbove` so the puck renders above the line.
  String? get routeLayerId => _polyManager?.id;

  Future<void> init() async {
    if (_disposed) return;
    // Creation order = render order: geofence fill beneath, route line, pin top.
    _polygonManager ??= await map.annotations.createPolygonAnnotationManager();
    _polyManager ??= await map.annotations.createPolylineAnnotationManager();
    _pointManager ??= await map.annotations.createPointAnnotationManager();
    _pinImage ??= await _buildPinImage();
  }

  static ({double lat, double lng})? _coords(TaskSummary task) =>
      taskShopLatLng(task);

  /// Switch the active task (null clears). If [currentPos] is supplied, kicks
  /// off the initial route fetch + camera fit immediately.
  Future<void> setTask(
    TaskSummary? task, {
    geo.Position? currentPos,
    bool fitCamera = true,
  }) async {
    if (_disposed) return;
    if (task == null) {
      await clear();
      return;
    }
    // Same task being set again — common when the route screen rebuilds or
    // _resumeNavigation runs after the active-task listener already fired.
    // Don't clear/redraw the pin & fence; but if we now have a position AND
    // haven't drawn the route yet, take this chance to draw it (otherwise we
    // race against onPositionUpdate, which is why the line sometimes never
    // appeared).
    if (_currentTask?.id == task.id) {
      if (_arrived) return;
      if (currentPos != null && _routeLine == null && !_fetching) {
        await _fetchAndDrawRoute(task, currentPos, fitCamera: fitCamera);
      }
      return;
    }
    await clear();
    _currentTask = task;
    await _drawGeofence(task);
    await _drawPin(task);

    // Already inside this task's fence (e.g. rebuilt after returning from
    // background while standing at the shop) → arrived; draw pin + fence but
    // never the route.
    if (AutoGeofenceService.instance.insideTaskId == task.id) {
      _arrived = true;
      return;
    }

    if (currentPos != null) {
      await _fetchAndDrawRoute(task, currentPos, fitCamera: fitCamera);
    }
  }

  Future<void> onPositionUpdate(geo.Position pos) async {
    if (_disposed) return;
    final task = _currentTask;
    if (task == null) return;
    // Arrival is terminal — never redraw/re-route once reached.
    if (_arrived) return;

    // Realtime: re-anchor the drawn polyline to the live position each fix.
    await _trimRouteToPosition(pos);

    if (_fetching) return;

    final last = _lastRoutedFrom;
    final now = DateTime.now();
    if (last == null) {
      await _fetchAndDrawRoute(task, pos, fitCamera: true);
      return;
    }
    final dist = geo.Geolocator.distanceBetween(
      last.latitude, last.longitude, pos.latitude, pos.longitude,
    );
    final aged = now.difference(_lastRouteAt) >= _reRouteMaxAge;
    if (dist < _reRouteDistanceMeters && !aged) return;

    await _fetchAndDrawRoute(task, pos, fitCamera: false);
  }

  /// Single source of truth for "arrived", driven by the geofence enter/exit
  /// event (relayed by the route screen). When true the route is removed and
  /// never redrawn for this task; resets when the task changes.
  Future<void> setReached(bool reached) async {
    if (_disposed) return;
    if (_arrived == reached) return;
    _arrived = reached;
    if (reached) {
      await _clearRouteLine();
      onChanged(null, false);
    }
  }

  /// Re-anchors the drawn polyline to start at [pos] — purely local, no API.
  Future<void> _trimRouteToPosition(geo.Position pos) async {
    final coords = _routeCoordinates;
    final line = _routeLine;
    if (coords == null || coords.length < 2 || line == null) return;
    if (_polyManager == null) return;

    var nearestIdx = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < coords.length; i++) {
      final d = geo.Geolocator.distanceBetween(
        pos.latitude, pos.longitude, coords[i][1], coords[i][0],
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }

    final trimmed = <Position>[Position(pos.longitude, pos.latitude)];
    for (var i = nearestIdx + 1; i < coords.length; i++) {
      trimmed.add(Position(coords[i][0], coords[i][1]));
    }
    if (trimmed.length < 2) {
      final lastC = coords.last;
      trimmed.add(Position(lastC[0], lastC[1]));
    }

    line.geometry = LineString(coordinates: trimmed);
    try {
      await _polyManager!.update(line);
    } catch (_) {/* line may have been swapped by a concurrent re-route */}
  }

  Future<void> _clearRouteLine() async {
    if (_routeLine != null && _polyManager != null) {
      try {
        await _polyManager!.delete(_routeLine!);
      } catch (_) {/* may already be gone */}
    }
    _routeLine = null;
    _routeCoordinates = null;
    _lastRoutedFrom = null;
    _lastRouteAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> clear() async {
    if (_routeLine != null && _polyManager != null) {
      try {
        await _polyManager!.delete(_routeLine!);
      } catch (_) {}
    }
    if (_shopPin != null && _pointManager != null) {
      try {
        await _pointManager!.delete(_shopPin!);
      } catch (_) {}
    }
    if (_geofence != null && _polygonManager != null) {
      try {
        await _polygonManager!.delete(_geofence!);
      } catch (_) {}
    }
    _routeLine = null;
    _shopPin = null;
    _geofence = null;
    _currentTask = null;
    _routeCoordinates = null;
    _lastRoutedFrom = null;
    _lastRouteAt = DateTime.fromMillisecondsSinceEpoch(0);
    _arrived = false;
    if (!_disposed) onChanged(null, false);
  }

  Future<void> dispose() async {
    _disposed = true;
    await clear();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Draws the shop's geofence as a geographically-accurate circle (64-point
  /// polygon) whose radius matches [GeofenceConfig.enterRadiusMeters], so the
  /// agent sees exactly how close they must get for a visit to register.
  Future<void> _drawGeofence(TaskSummary task) async {
    final c = _coords(task);
    if (c == null || _polygonManager == null) return;

    final ring = _circlePolygon(
      c.lat, c.lng, GeofenceConfig.enterRadiusMeters,
    );

    _geofence = await _polygonManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [ring]),
        fillColor: _kBrand.toARGB32(),
        fillOpacity: 0.12,
        fillOutlineColor: _kBrand.toARGB32(),
      ),
    );
  }

  static List<Position> _circlePolygon(
    double centerLat,
    double centerLng,
    double radiusMeters, {
    int points = 64,
  }) {
    const earthRadius = 6378137.0; // metres (WGS-84)
    final latRad = centerLat * math.pi / 180.0;
    final dLat = (radiusMeters / earthRadius) * 180.0 / math.pi;
    final dLng =
        (radiusMeters / (earthRadius * math.cos(latRad))) * 180.0 / math.pi;

    final ring = <Position>[];
    for (var i = 0; i <= points; i++) {
      final theta = 2 * math.pi * i / points;
      ring.add(Position(
        centerLng + dLng * math.cos(theta),
        centerLat + dLat * math.sin(theta),
      ));
    }
    return ring;
  }

  Future<void> _drawPin(TaskSummary task) async {
    final c = _coords(task);
    if (c == null || _pointManager == null || _pinImage == null) return;

    _shopPin = await _pointManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(c.lng, c.lat)),
        image: _pinImage,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
        textField: task.shop?.name ?? task.title,
        textOffset: [0, -3.5],
        textSize: 13,
        textColor: AppColors.ink.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2,
      ),
    );
  }

  Future<void> _fetchAndDrawRoute(
    TaskSummary task,
    geo.Position from, {
    required bool fitCamera,
  }) async {
    final c = _coords(task);
    if (c == null || _polyManager == null) return;

    _fetching = true;
    onChanged(null, true);
    _lastRoutedFrom = from;
    _lastRouteAt = DateTime.now();

    try {
      final route = await MapboxDirectionsService.instance.drivingRoute(
        originLat: from.latitude,
        originLng: from.longitude,
        destLat: c.lat,
        destLng: c.lng,
      );
      if (_disposed) return;
      if (_currentTask?.id != task.id) return; // task changed mid-fetch
      if (route == null || route.geometry.isEmpty) {
        onChanged(null, false);
        return;
      }

      if (_routeLine != null) {
        try {
          await _polyManager!.delete(_routeLine!);
        } catch (_) {}
      }
      final positions = route.geometry
          .map((p) => Position(p[0], p[1]))
          .toList(growable: false);
      _routeLine = await _polyManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: _kBrand.toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 0.9,
        ),
      );
      _routeCoordinates = route.geometry;

      onChanged(route, false);

      if (fitCamera) {
        await _fitToRoute(from, c.lat, c.lng);
      }
    } catch (_) {
      if (!_disposed) onChanged(null, false);
    } finally {
      _fetching = false;
    }
  }

  Future<void> _fitToRoute(
    geo.Position from,
    double dstLat,
    double dstLng,
  ) async {
    final cam = await map.cameraForCoordinatesPadding(
      [
        Point(coordinates: Position(from.longitude, from.latitude)),
        Point(coordinates: Position(dstLng, dstLat)),
      ],
      CameraOptions(),
      MbxEdgeInsets(top: 80, left: 40, bottom: 80, right: 40),
      null,
      null,
    );
    final clamped = CameraOptions(
      center: cam.center,
      zoom: (cam.zoom ?? 14).clamp(10.0, 16.0),
      bearing: cam.bearing,
      pitch: cam.pitch,
      anchor: cam.anchor,
      padding: cam.padding,
    );
    await map.flyTo(clamped, MapAnimationOptions(duration: 1000));
  }

  /// Renders a Google-Maps-style teardrop pin to a PNG via Canvas (no asset).
  static Future<Uint8List> _buildPinImage() async {
    const double w = 84;
    const double h = 116;
    const double cx = w / 2;
    const double headCy = 34;
    const double headR = 26;
    const double tipY = h - 14;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, h - 8), width: 30, height: 8),
      shadowPaint,
    );

    final path = Path();
    const tangentDx = headR * 0.86;
    const tangentDy = headR * 0.50;
    path.moveTo(cx - tangentDx, headCy + tangentDy);
    path.lineTo(cx, tipY);
    path.lineTo(cx + tangentDx, headCy + tangentDy);
    path.arcToPoint(
      Offset(cx - tangentDx, headCy + tangentDy),
      radius: const Radius.circular(headR),
      largeArc: true,
      clockwise: false,
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.red16
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      const Offset(cx, headCy),
      8.5,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
