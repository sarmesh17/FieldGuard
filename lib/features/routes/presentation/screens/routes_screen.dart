import 'dart:async';
import 'dart:math' as math;

import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/routes/presentation/screens/components/create_geofence_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const _geofenceRadius = 50.0; // metres

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapOverlayVisible = true;
  geo.Position? _lastPosition;

  // Geofence state
  Position? _geofenceCenter;
  bool _geofenceActive = false;
  bool _isInsideGeofence = false;
  StreamSubscription<geo.Position>? _positionStream;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _geofencePolygon;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ── Map initialisation ──────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initMap();
  }

  Future<void> _initMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _mapOverlayVisible = false);
      return;
    }
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    await _autoGoToLocation();
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
        final flyFuture = _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1200),
        );
        setState(() => _mapOverlayVisible = false);
        await flyFuture;
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

  // ── Geofence ────────────────────────────────────────────────────────────────

  Future<void> _setGeofence() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;

    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    _lastPosition = pos;

    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGeofenceForm(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ),
    );

    if (confirmed != true) return;

    final center = Position(pos.longitude, pos.latitude);
    await _drawGeofenceCircle(center);
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: center),
        zoom: 16.5,
      ),
      MapAnimationOptions(duration: 1000),
    );

    setState(() {
      _geofenceCenter = center;
      _geofenceActive = true;
      _isInsideGeofence = true;
    });

    _startPositionStream();
  }

  Future<void> _clearGeofence() async {
    _positionStream?.cancel();
    _positionStream = null;

    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
      _geofencePolygon = null;
    }

    setState(() {
      _geofenceCenter = null;
      _geofenceActive = false;
      _isInsideGeofence = false;
    });
  }

  Future<void> _drawGeofenceCircle(Position center) async {
    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
    }
    _polygonManager ??=
        await _mapboxMap!.annotations.createPolygonAnnotationManager();

    _geofencePolygon = await _polygonManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(
          coordinates: [_circlePoints(center, _geofenceRadius)],
        ),
        fillColor: const Color(0xff0E5A3B).toARGB32(),
        fillOpacity: 0.18,
        fillOutlineColor: const Color(0xff0E5A3B).toARGB32(),
      ),
    );
  }

  void _startPositionStream() {
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(geo.Position current) {
    if (_geofenceCenter == null) return;

    final distance = geo.Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _geofenceCenter!.lat.toDouble(),
      _geofenceCenter!.lng.toDouble(),
    );

    final nowInside = distance <= _geofenceRadius;

    if (nowInside && !_isInsideGeofence) {
      setState(() => _isInsideGeofence = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 8),
              Text('Entered geofence zone',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xff0E5A3B),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else if (!nowInside && _isInsideGeofence) {
      setState(() => _isInsideGeofence = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Left geofence zone',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<Position> _circlePoints(Position center, double radiusMeters) {
    const earthRadius = 6371000.0;
    final lat = center.lat.toDouble() * math.pi / 180;
    final lng = center.lng.toDouble() * math.pi / 180;
    final d = radiusMeters / earthRadius;
    const n = 64;
    return List.generate(n + 1, (i) {
      final bearing = (2 * math.pi * i) / n;
      final pLat = math.asin(math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(bearing));
      final pLng = lng +
          math.atan2(math.sin(bearing) * math.sin(d) * math.cos(lat),
              math.cos(d) - math.sin(lat) * math.sin(pLat));
      return Position(pLng * 180 / math.pi, pLat * 180 / math.pi);
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Text(
                  'Today\'s Route',
                  style: TextStyle(
                    color: const Color(0xff111111),
                    fontWeight: FontWeight.w700,
                    fontSize: SizeConfig.scaledFontSize(20),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.scale(12),
                    vertical: SizeConfig.scale(6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffDDF5E0),
                    borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
                  ),
                  child: Text(
                    '8 Shops',
                    style: TextStyle(
                      fontSize: SizeConfig.scaledFontSize(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0E5A3B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMapSection(),
                _buildNextStopSection(),
                _buildTodayScheduleSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapSection() {
    final mapHeight = SizeConfig.heightPercent(35).clamp(200.0, 300.0);

    return SizedBox(
      width: double.infinity,
      height: mapHeight + 24,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.scale(16),
              SizeConfig.scale(16),
              SizeConfig.scale(16),
              0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
              child: SizedBox(
                width: double.infinity,
                height: mapHeight,
                child: Stack(
                  children: [
                    MapWidget(
                      key: const ValueKey('adminRouteMap'),
                      styleUri: MapboxStyles.STANDARD,
                      textureView: true,
                      onMapCreated: _onMapCreated,
                    ),
                    if (_isLocating && !_mapOverlayVisible)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xff0E5A3B),
                          backgroundColor: Color(0xffDDF5E0),
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
                  ],
                ),
              ),
            ),
          ),

          // Geofence status chip — top left
          if (_geofenceActive)
            Positioned(
              top: SizeConfig.scale(24),
              left: SizeConfig.scale(24),
              child: _GeofenceStatusChip(inside: _isInsideGeofence),
            ),

          // Fullscreen — top right
          Positioned(
            top: SizeConfig.scale(24),
            right: SizeConfig.scale(24),
            child: _MapIconButton(
              icon: Icons.fullscreen,
              onTap: _openFullscreen,
            ),
          ),

          // Fence toggle — bottom left
          Positioned(
            bottom: SizeConfig.scale(8),
            left: SizeConfig.scale(24),
            child: _MapIconButton(
              icon: _geofenceActive ? Icons.fence : Icons.fence_outlined,
              color: _geofenceActive
                  ? const Color(0xff0E5A3B)
                  : const Color(0xff6B7280),
              onTap: _geofenceActive ? _clearGeofence : _setGeofence,
            ),
          ),

          // My location — bottom right
          Positioned(
            bottom: SizeConfig.scale(8),
            right: SizeConfig.scale(24),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MapFullscreenScreen(
          initialLat: _lastPosition?.latitude,
          initialLng: _lastPosition?.longitude,
        ),
      ),
    );
  }

  Widget _buildNextStopSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      padding: EdgeInsets.all(SizeConfig.scale(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT STOP',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(12),
              fontWeight: FontWeight.w600,
              color: const Color(0xff667085),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: SizeConfig.scale(12)),
          Text(
            'Starlight Convenience',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(24),
              fontWeight: FontWeight.w700,
              color: const Color(0xff111111),
            ),
          ),
          SizedBox(height: SizeConfig.scale(8)),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: SizeConfig.scale(16), color: const Color(0xff667085)),
              SizedBox(width: SizeConfig.scale(4)),
              Expanded(
                child: Text(
                  '4200 Broadway St, New York',
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(14),
                    color: const Color(0xff667085),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(8)),
          Row(
            children: [
              Icon(Icons.directions_car,
                  size: SizeConfig.scale(16), color: const Color(0xff0E5A3B)),
              SizedBox(width: SizeConfig.scale(4)),
              Text(
                '2.3 km',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff0E5A3B),
                ),
              ),
              SizedBox(width: SizeConfig.scale(8)),
              Text(
                '~8 min',
                style: TextStyle(
                  fontSize: SizeConfig.scaledFontSize(14),
                  color: const Color(0xff667085),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.scale(20)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation, size: 20),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0E5A3B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.scale(12)),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.scale(12)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call Shop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff0E5A3B),
                    side: const BorderSide(color: Color(0xff0E5A3B)),
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.scale(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.scale(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Schedule',
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(18),
              fontWeight: FontWeight.w700,
              color: const Color(0xff111111),
            ),
          ),
          SizedBox(height: SizeConfig.scale(16)),
          _buildScheduleItem(
              number: '1',
              shopName: 'Sunrise Market',
              status: 'Visited 10:30 AM',
              isVisited: true),
          SizedBox(height: SizeConfig.scale(12)),
          _buildScheduleItem(
              number: '2',
              shopName: 'Starlight Convenience',
              status: 'Next Stop',
              isVisited: false,
              isCurrent: true),
          SizedBox(height: SizeConfig.scale(12)),
          _buildScheduleItem(
              number: '3',
              shopName: 'Green Valley Store',
              status: 'Pending',
              isVisited: false),
          SizedBox(height: SizeConfig.scale(12)),
          _buildScheduleItem(
              number: '4',
              shopName: 'Downtown Market',
              status: 'Pending',
              isVisited: false),
          SizedBox(height: SizeConfig.scale(12)),
          _buildScheduleItem(
              number: '5',
              shopName: 'City Center Shop',
              status: 'Pending',
              isVisited: false),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String number,
    required String shopName,
    required String status,
    required bool isVisited,
    bool isCurrent = false,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xffDDF5E0) : Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(
          color: isCurrent
              ? const Color(0xff0E5A3B)
              : const Color(0xffE8E3DD),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: SizeConfig.scale(40),
            height: SizeConfig.scale(40),
            decoration: BoxDecoration(
              color: isVisited
                  ? const Color(0xff0E5A3B)
                  : isCurrent
                      ? Colors.white
                      : const Color(0xffF8FAF9),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: const Color(0xff0E5A3B), width: 2)
                  : null,
            ),
            child: Center(
              child: isVisited
                  ? Icon(Icons.check,
                      color: Colors.white, size: SizeConfig.scale(20))
                  : Text(
                      number,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(16),
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? const Color(0xff0E5A3B)
                            : const Color(0xff667085),
                      ),
                    ),
            ),
          ),
          SizedBox(width: SizeConfig.scale(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: SizeConfig.scaledFontSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff111111),
                  ),
                ),
                SizedBox(height: SizeConfig.scale(4)),
                Row(
                  children: [
                    if (isVisited)
                      Icon(Icons.check_circle,
                          size: SizeConfig.scale(14),
                          color: const Color(0xff0E5A3B))
                    else if (isCurrent)
                      Icon(Icons.navigation,
                          size: SizeConfig.scale(14),
                          color: const Color(0xff0E5A3B))
                    else
                      Icon(Icons.schedule,
                          size: SizeConfig.scale(14),
                          color: const Color(0xff667085)),
                    SizedBox(width: SizeConfig.scale(4)),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13),
                        color: isVisited || isCurrent
                            ? const Color(0xff0E5A3B)
                            : const Color(0xff667085),
                        fontWeight: isVisited || isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: SizeConfig.scale(16), color: const Color(0xff667085)),
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

  Widget _buildRing(int index) {
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
              border: Border.all(
                  color: const Color(0xff0E5A3B), width: 1.5),
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
                  _buildRing(2),
                  _buildRing(1),
                  _buildRing(0),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff0E5A3B),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0E5A3B)
                              .withValues(alpha: 0.35),
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

// ── Geofence status chip ───────────────────────────────────────────────────────

class _GeofenceStatusChip extends StatelessWidget {
  final bool inside;
  const _GeofenceStatusChip({required this.inside});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inside ? const Color(0xff0E5A3B) : Colors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            inside ? 'Inside Geofence' : 'Outside Geofence',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fullscreen map screen ──────────────────────────────────────────────────────

class _MapFullscreenScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _MapFullscreenScreen({this.initialLat, this.initialLng});

  @override
  State<_MapFullscreenScreen> createState() => _MapFullscreenScreenState();
}

class _MapFullscreenScreenState extends State<_MapFullscreenScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapOverlayVisible = true;

  // Geofence state
  Position? _geofenceCenter;
  bool _geofenceActive = false;
  bool _isInsideGeofence = false;
  StreamSubscription<geo.Position>? _positionStream;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _geofencePolygon;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initMap();
  }

  Future<void> _initMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _mapOverlayVisible = false);
      return;
    }
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    final lat = widget.initialLat;
    final lng = widget.initialLng;

    if (lat != null && lng != null) {
      final flyFuture = _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
        ),
      );
      if (mounted) setState(() => _mapOverlayVisible = false);
      await flyFuture;
    } else {
      await _autoGoToLocation();
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
      if (mounted) {
        final flyFuture = _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1200),
        );
        setState(() => _mapOverlayVisible = false);
        await flyFuture;
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

  // ── Geofence (fullscreen) ───────────────────────────────────────────────────

  Future<void> _setGeofence() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;

    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGeofenceForm(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ),
    );

    if (confirmed != true) return;

    final center = Position(pos.longitude, pos.latitude);
    await _drawGeofenceCircle(center);
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: center),
        zoom: 16.5,
      ),
      MapAnimationOptions(duration: 1000),
    );

    setState(() {
      _geofenceCenter = center;
      _geofenceActive = true;
      _isInsideGeofence = true;
    });

    _startPositionStream();
  }

  Future<void> _clearGeofence() async {
    _positionStream?.cancel();
    _positionStream = null;
    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
      _geofencePolygon = null;
    }
    setState(() {
      _geofenceCenter = null;
      _geofenceActive = false;
      _isInsideGeofence = false;
    });
  }

  Future<void> _drawGeofenceCircle(Position center) async {
    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
    }
    _polygonManager ??=
        await _mapboxMap!.annotations.createPolygonAnnotationManager();

    _geofencePolygon = await _polygonManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(
          coordinates: [_circlePoints(center, _geofenceRadius)],
        ),
        fillColor: const Color(0xff0E5A3B).toARGB32(),
        fillOpacity: 0.18,
        fillOutlineColor: const Color(0xff0E5A3B).toARGB32(),
      ),
    );
  }

  void _startPositionStream() {
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(geo.Position current) {
    if (_geofenceCenter == null) return;
    final distance = geo.Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _geofenceCenter!.lat.toDouble(),
      _geofenceCenter!.lng.toDouble(),
    );
    final nowInside = distance <= _geofenceRadius;
    if (nowInside != _isInsideGeofence) {
      setState(() => _isInsideGeofence = nowInside);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(
                nowInside ? Icons.location_on : Icons.location_off,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                nowInside ? 'Entered geofence zone' : 'Left geofence zone',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ]),
            backgroundColor:
                nowInside ? const Color(0xff0E5A3B) : Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<Position> _circlePoints(Position center, double radiusMeters) {
    const earthRadius = 6371000.0;
    final lat = center.lat.toDouble() * math.pi / 180;
    final lng = center.lng.toDouble() * math.pi / 180;
    final d = radiusMeters / earthRadius;
    const n = 64;
    return List.generate(n + 1, (i) {
      final bearing = (2 * math.pi * i) / n;
      final pLat = math.asin(math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(bearing));
      final pLng = lng +
          math.atan2(math.sin(bearing) * math.sin(d) * math.cos(lat),
              math.cos(d) - math.sin(lat) * math.sin(pLat));
      return Position(pLng * 180 / math.pi, pLat * 180 / math.pi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('adminRouteMapFullscreen'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          if (_isLocating && !_mapOverlayVisible)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xff0E5A3B),
                backgroundColor: Color(0xffDDF5E0),
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

          // Geofence status chip
          if (_geofenceActive)
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Center(
                child: _GeofenceStatusChip(inside: _isInsideGeofence),
              ),
            ),

          // Back
          Positioned(
            top: 48,
            left: 16,
            child: _MapIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Fence toggle
          Positioned(
            bottom: 48,
            left: 16,
            child: _MapIconButton(
              icon: _geofenceActive ? Icons.fence : Icons.fence_outlined,
              color: _geofenceActive
                  ? const Color(0xff0E5A3B)
                  : const Color(0xff6B7280),
              onTap: _geofenceActive ? _clearGeofence : _setGeofence,
            ),
          ),

          // My location
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

// ── Shared map overlay button ──────────────────────────────────────────────────

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MapIconButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xff0E5A3B),
  });

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
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
