import 'package:fieldguard/features/routes/presentation/screens/components/create_geofence_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// Fullscreen map for creating a new shop.
///
/// Mirrors the geofence-creation flow: the user inspects the map, taps
/// "Create Shop Here", and the [CreateGeofenceForm] bottom sheet runs the
/// actual API call. Pops `true` once a shop was created so the caller can
/// refresh its list.
class CreateShopMapScreen extends StatefulWidget {
  const CreateShopMapScreen({super.key});

  @override
  State<CreateShopMapScreen> createState() => _CreateShopMapScreenState();
}

class _CreateShopMapScreenState extends State<CreateShopMapScreen> {
  static const _brand = AppColors.green;

  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  bool _mapLoading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
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
      if (mounted) setState(() => _mapLoading = false);
      return;
    }
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    await _goToMyLocation();
    if (mounted) setState(() => _mapLoading = false);
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

    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (_) {
      // Keep the map as-is; user can still create at their location.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// The shop location is the map's current centre (where the fixed pin
  /// points) — NOT the device GPS. This lets the user nudge the map so the pin
  /// sits exactly on the storefront even if they're standing a few metres off.
  Future<void> _createShopHere() async {
    if (_creating) return;
    final map = _mapboxMap;
    if (map == null) return;

    setState(() => _creating = true);
    try {
      final cam = await map.getCameraState();
      final lat = cam.center.coordinates.lat.toDouble();
      final lng = cam.center.coordinates.lng.toDouble();
      if (!mounted) return;

      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CreateGeofenceForm(latitude: lat, longitude: lng),
      );

      if (created == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the map location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('createShopMap'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          if (_isLocating && !_mapLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _brand,
                backgroundColor: AppColors.green6,
              ),
            ),

          if (_mapLoading)
            const ColoredBox(
              color: AppColors.white,
              child: Center(child: CircularProgressIndicator(color: _brand)),
            ),

          // Fixed centre pin — the map pans under it; wherever it points is the
          // shop location. IgnorePointer so it never eats map gestures.
          if (!_mapLoading)
            const Positioned.fill(child: IgnorePointer(child: _CenterPin())),

          // Back
          Positioned(
            top: 48,
            left: 16,
            child: _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // My location
          Positioned(
            bottom: 110,
            right: 16,
            child: _CircleIconButton(
              icon: Icons.my_location,
              onTap: _goToMyLocation,
            ),
          ),

          // Helper hint
          Positioned(
            top: 52,
            left: 72,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Move the map so the pin sits on the shop, then tap Create Shop Here',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
          ),

          // Create shop action
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _createShopHere,
                icon: _creating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_location_alt, size: 22),
                label: Text(_creating ? 'Please wait…' : 'Create Shop Here'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed marker that floats at the centre of the map. Its tip rests on the
/// precise centre dot — that point is read back as the shop's coordinates.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  static const _brand = AppColors.green;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pin lifted so its pointed tip lands on the centre dot below.
        Transform.translate(
          offset: const Offset(0, -23),
          child: Icon(
            Icons.location_on,
            size: 50,
            color: _brand,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Precise centre dot (the exact coordinate the pin marks).
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _brand,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: AppColors.green, size: 20),
      ),
    );
  }
}
