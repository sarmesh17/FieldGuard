part of 'routes_screen.dart';

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
              .where(
                (s) =>
                    s.shop.name.toLowerCase().contains(q) ||
                    s.shop.address.toLowerCase().contains(q),
              )
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
                color: AppColors.grey7,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Shop',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search shops…',
              prefixIcon: const Icon(Icons.search, color: AppColors.grey2),
              filled: true,
              fillColor: AppColors.white3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
                child: Text(
                  'No shops found',
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.white4),
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
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: _kBrand,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      s.shop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    subtitle: Text(
                      s.shop.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    trailing: hasCoords
                        ? const Icon(
                            Icons.chevron_right,
                            color: AppColors.grey,
                          )
                        : const Tooltip(
                            message: 'No saved location',
                            child: Icon(
                              Icons.location_off_outlined,
                              color: AppColors.red,
                              size: 18,
                            ),
                          ),
                    enabled: hasCoords,
                    onTap: hasCoords
                        ? () => Navigator.of(context).pop(s)
                        : null,
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
      color: AppColors.white2,
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
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AnimatedDotsText(
              base: 'Getting your location',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey,
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

/// Fades + slides its child up on first build, with a small per-index delay so
/// list items cascade in one after another instead of all at once.
class _AnimatedEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({required this.index, required this.child});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Cap the stagger so long lists don't take forever to finish appearing.
    final delayMs = (widget.index.clamp(0, 8)) * 70;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
