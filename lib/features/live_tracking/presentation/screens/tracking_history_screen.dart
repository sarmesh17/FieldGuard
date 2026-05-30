import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/datasource/tracking_history_datasource_impl.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';
import 'package:fieldguard/features/live_tracking/data/usecase/get_tracking_history_usecase.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const _kBrand = Color(0xff0E5A3B);
const _kInk = Color(0xff111111);
const _kMuted = Color(0xff667085);
const _kEnd = Color(0xffC0392B);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

GetTrackingHistoryUsecase _buildUsecase() => GetTrackingHistoryUsecase(
      TrackingHistoryDataSourceImpl(DioClient.createDio()),
    );

// ── Friendly formatters (manager/employee facing — no jargon) ───────────────

String _fmtTime(DateTime dt) {
  final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '$h12:$min $ampm';
}

/// "Today" / "Yesterday" / "May 24, 2026".
String _relativeDay(DateTime dt) {
  final now = DateTime.now();
  final d = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _fmtDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours} hr ${d.inMinutes.remainder(60)} min';
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} sec';
}

String _fmtDistance(double metres) {
  if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${metres.round()} m';
}

/// Full-screen tracking history for an employee — a plain list of tracking
/// sessions (when / how long / how far). Tapping one opens its route on a map.
class TrackingHistoryScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const TrackingHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<TrackingHistoryScreen> createState() => _TrackingHistoryScreenState();
}

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen> {
  late final GetTrackingHistoryUsecase _usecase;

  List<TrackingSession> _sessions = [];
  bool _loading = true;
  String? _error;

  // Filters
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _usecase = _buildUsecase();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _usecase(
      employeeId: widget.employeeId,
      from: _from?.toUtc().toIso8601String(),
      to: _to?.toUtc().toIso8601String(),
    );

    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        final sessions = [...data.sessions]
          ..sort((a, b) => (b.startedAt ?? DateTime(0))
              .compareTo(a.startedAt ?? DateTime(0)));
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      case Failure(:final exception):
        setState(() {
          _error = exception.toString();
          _loading = false;
        });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)), end: now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kBrand,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _from = picked.start;
      _to = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    });
    _load();
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
    });
    _load();
  }

  void _openSession(TrackingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SessionRouteScreen(
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          session: session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: _kBrand,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  widget.employeeName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _from != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: _pickDateRange,
                tooltip: 'Filter by date',
              ),
            ],
          ),
          body: Column(
            children: [
              if (_from != null && _to != null)
                _FilterChipBar(
                  from: _from!,
                  to: _to!,
                  onClear: _clearFilters,
                ),
              Expanded(
                child: _loading
                    ? const SkeletonList()
                    : _error != null
                        ? _ErrorView(message: _error!, onRetry: _load)
                        : _sessions.isEmpty
                            ? const _EmptyView()
                            : RefreshIndicator(
                                color: _kBrand,
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 32),
                                  itemCount: _sessions.length,
                                  itemBuilder: (_, i) => _SessionCard(
                                    session: _sessions[i],
                                    onTap: () => _openSession(_sessions[i]),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChipBar extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final VoidCallback onClear;

  const _FilterChipBar(
      {required this.from, required this.to, required this.onClear});

  @override
  Widget build(BuildContext context) {
    String d(DateTime x) => '${_months[x.month - 1]} ${x.day}, ${x.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _kBrand.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, size: 16, color: _kBrand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${d(from)} — ${d(to)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kBrand,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _kBrand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Session summary card (plain language) ───────────────────────────────────

class _SessionCard extends StatelessWidget {
  final TrackingSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final started = session.startedAt?.toLocal();
    final ended = session.endedAt?.toLocal();
    final duration = session.duration;
    final live = session.isActive && ended == null;

    final timeRange = started == null
        ? 'Time not recorded'
        : live
            ? 'Started ${_fmtTime(started)} · still tracking'
            : ended != null
                ? '${_fmtTime(started)} – ${_fmtTime(ended)}'
                : 'Started ${_fmtTime(started)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE8EDEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kBrand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.map_rounded, size: 21, color: _kBrand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            started != null
                                ? _relativeDay(started)
                                : 'Unknown date',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _kInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeRange,
                            style: const TextStyle(
                                fontSize: 12.5, color: _kMuted),
                          ),
                        ],
                      ),
                    ),
                    if (live)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffDDF5E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record,
                                size: 9, color: _kBrand),
                            SizedBox(width: 4),
                            Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kBrand,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xffAAB2BD)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (duration != null)
                      _StatChip(
                        icon: Icons.schedule_rounded,
                        label: _fmtDuration(duration),
                      ),
                    if (session.totalDistance > 0)
                      _StatChip(
                        icon: Icons.straighten_rounded,
                        label: _fmtDistance(session.totalDistance),
                      ),
                    _StatChip(
                      icon: Icons.my_location_rounded,
                      label: '${session.pointCount} locations',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF0F2F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared empty / error views ──────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: SizeConfig.scale(56), color: const Color(0xffAAB2BD)),
          const SizedBox(height: 14),
          const Text(
            'No tracking yet',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _kMuted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tracking sessions will appear here',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: SizeConfig.scale(56), color: _kEnd),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Session route — the recorded path drawn on a map (no GPS jargon).
// ═══════════════════════════════════════════════════════════════════════════

class _SessionRouteScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final TrackingSession session;

  const _SessionRouteScreen({
    required this.employeeId,
    required this.employeeName,
    required this.session,
  });

  @override
  State<_SessionRouteScreen> createState() => _SessionRouteScreenState();
}

class _SessionRouteScreenState extends State<_SessionRouteScreen> {
  static const _green = _kBrand;

  late final GetTrackingHistoryUsecase _usecase;

  MapboxMap? _map;
  PolylineAnnotationManager? _lines;
  CircleAnnotationManager? _circles;

  List<TrackingPoint>? _points; // null = still loading
  String? _error;

  @override
  void initState() {
    super.initState();
    _usecase = _buildUsecase();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _usecase.route(
      employeeId: widget.employeeId,
      sessionId: widget.session.id,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        // Keep only valid fixes, ordered oldest → newest.
        final pts = data.points
            .where((p) => !(p.latitude == 0 && p.longitude == 0))
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        setState(() => _points = pts);
        _drawIfReady();
      case Failure(:final exception):
        setState(() => _error = exception.toString());
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _lines = await map.annotations.createPolylineAnnotationManager();
    _circles = await map.annotations.createCircleAnnotationManager();
    _drawIfReady();
  }

  Future<void> _drawIfReady() async {
    final map = _map;
    final lines = _lines;
    final circles = _circles;
    final pts = _points;
    if (map == null || lines == null || circles == null || pts == null) return;
    if (pts.isEmpty) return;

    final positions = pts
        .map((p) => Position(p.longitude, p.latitude))
        .toList(growable: false);

    if (positions.length >= 2) {
      await lines.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: _green.toARGB32(),
          lineWidth: 5.0,
          lineOpacity: 0.85,
        ),
      );
    }

    // Start (green) + end (red) markers.
    await circles.create(CircleAnnotationOptions(
      geometry: Point(coordinates: positions.first),
      circleRadius: 8.0,
      circleColor: _green.toARGB32(),
      circleStrokeColor: Colors.white.toARGB32(),
      circleStrokeWidth: 3.0,
    ));
    if (positions.length >= 2) {
      await circles.create(CircleAnnotationOptions(
        geometry: Point(coordinates: positions.last),
        circleRadius: 8.0,
        circleColor: _kEnd.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ));
    }

    await _fitTo(pts);
  }

  Future<void> _fitTo(List<TrackingPoint> pts) async {
    final map = _map;
    if (map == null) return;
    final coords = pts
        .map((p) => Point(coordinates: Position(p.longitude, p.latitude)))
        .toList(growable: false);
    if (coords.length == 1) {
      await map.flyTo(
        CameraOptions(center: coords.first, zoom: 15.0),
        MapAnimationOptions(duration: 700),
      );
      return;
    }
    final cam = await map.cameraForCoordinatesPadding(
      coords,
      CameraOptions(),
      MbxEdgeInsets(top: 120, left: 50, bottom: 220, right: 50),
      null,
      null,
    );
    await map.flyTo(
      CameraOptions(
        center: cam.center,
        zoom: (cam.zoom ?? 14).clamp(3.0, 16.0),
        padding: cam.padding,
      ),
      MapAnimationOptions(duration: 900),
    );
  }

  @override
  Widget build(BuildContext context) {
    final started = widget.session.startedAt?.toLocal();
    final ended = widget.session.endedAt?.toLocal();
    final duration = widget.session.duration;
    final pts = _points;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('sessionRouteMap'),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          // Top bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _circleBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: _pill,
                    child: Text(
                      started != null
                          ? '${_relativeDay(started)} · ${_fmtTime(started)}'
                          : widget.employeeName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading / error / empty overlays
          if (_error != null)
            _OverlayCard(
              icon: Icons.error_outline_rounded,
              text: _error!,
              actionLabel: 'Retry',
              onAction: _load,
            )
          else if (pts == null)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _kBrand,
                backgroundColor: Color(0xffDDF5E0),
              ),
            )
          else if (pts.isEmpty)
            const _OverlayCard(
              icon: Icons.location_off_rounded,
              text: 'No location was recorded for this session.',
            ),

          // Bottom summary
          if (pts != null && pts.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      started != null && ended != null
                          ? '${_fmtTime(started)} – ${_fmtTime(ended)}'
                          : started != null
                              ? 'Started ${_fmtTime(started)}'
                              : 'This trip',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Metric(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: duration != null
                              ? _fmtDuration(duration)
                              : '—',
                        ),
                        _Metric(
                          icon: Icons.straighten_rounded,
                          label: 'Distance',
                          value: _fmtDistance(widget.session.totalDistance),
                        ),
                        _Metric(
                          icon: Icons.my_location_rounded,
                          label: 'Locations',
                          value: '${pts.length}',
                        ),
                      ],
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
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _kMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _OverlayCard({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 104,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: _kMuted),
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kBrand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
