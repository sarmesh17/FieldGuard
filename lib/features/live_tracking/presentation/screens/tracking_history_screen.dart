import 'dart:async';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/datasource/tracking_history_datasource_impl.dart';
import 'package:fieldguard/features/live_tracking/data/dto/tracking_history_response.dart';
import 'package:fieldguard/features/live_tracking/data/usecase/get_tracking_history_usecase.dart';
import 'package:flutter/material.dart';

const _kBrand = Color(0xff0E5A3B);
const _kInk = Color(0xff111111);
const _kMuted = Color(0xff667085);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Full-screen tracking session history for an employee.
///
/// Shows a timeline of GPS breadcrumbs grouped by session. Each point
/// displays coordinates, speed, accuracy, and timestamp. Supports date
/// range filtering via a bottom sheet.
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

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final GetTrackingHistoryUsecase _usecase;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  List<TrackingPoint> _points = [];
  bool _loading = true;
  String? _error;

  // Filters
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _usecase = GetTrackingHistoryUsecase(
      TrackingHistoryDataSourceImpl(DioClient.createDio()),
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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
        setState(() {
          _points = data.points;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      case Failure(:final exception):
        setState(() {
          _error = exception.toString();
          _loading = false;
        });
    }
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Groups points by sessionId (or all together if sessionId is null).
  Map<int?, List<TrackingPoint>> _groupBySession() {
    final map = <int?, List<TrackingPoint>>{};
    for (final p in _points) {
      map.putIfAbsent(p.sessionId, () => []).add(p);
    }
    return map;
  }

  String _fmtDateTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${_months[dt.month - 1]} ${dt.day} · $h12:$min $ampm';
  }

  String _fmtDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  // ── Build ────────────────────────────────────────────────────────────────

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
              // Active filter chip
              if (_from != null && _to != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: _kBrand.withValues(alpha: 0.06),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 16, color: _kBrand),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_fmtDate(_from!)} — ${_fmtDate(_to!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kBrand,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                ),

              // Body
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kBrand))
                    : _error != null
                        ? _buildError()
                        : _points.isEmpty
                            ? _buildEmpty()
                            : _buildTimeline(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: SizeConfig.scale(56), color: const Color(0xffC0392B)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: SizeConfig.scale(56),
              color: const Color(0xffAAB2BD)),
          const SizedBox(height: 14),
          const Text(
            'No tracking data found',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _kMuted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting the date range filter',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final sessions = _groupBySession();
    final sessionKeys = sessions.keys.toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: sessionKeys.length,
        itemBuilder: (_, i) {
          final sid = sessionKeys[i];
          final pts = sessions[sid]!;
          return _SessionCard(
            sessionId: sid,
            points: pts,
            fmtDateTime: _fmtDateTime,
            isLast: i == sessionKeys.length - 1,
          );
        },
      ),
    );
  }
}

// ─── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final int? sessionId;
  final List<TrackingPoint> points;
  final String Function(String) fmtDateTime;
  final bool isLast;

  const _SessionCard({
    required this.sessionId,
    required this.points,
    required this.fmtDateTime,
    required this.isLast,
  });

  String _duration() {
    if (points.length < 2) return '';
    final first = DateTime.tryParse(points.first.recordedAt);
    final last = DateTime.tryParse(points.last.recordedAt);
    if (first == null || last == null) return '';
    final diff = last.difference(first).abs();
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xffF8FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.route_rounded, size: 18, color: _kBrand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionId != null
                            ? 'Session #$sessionId'
                            : 'Tracking Points',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${points.length} points${_duration().isNotEmpty ? ' · $_duration()' : ''}',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${points.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _kBrand,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline points (show max 10, rest collapsed)
          _PointsTimeline(
            points: points,
            fmtDateTime: fmtDateTime,
          ),
        ],
      ),
    );
  }
}

// ─── Timeline points ───────────────────────────────────────────────────────────

class _PointsTimeline extends StatefulWidget {
  final List<TrackingPoint> points;
  final String Function(String) fmtDateTime;

  const _PointsTimeline({required this.points, required this.fmtDateTime});

  @override
  State<_PointsTimeline> createState() => _PointsTimelineState();
}

class _PointsTimelineState extends State<_PointsTimeline> {
  static const _previewCount = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.points;
    final visible =
        _expanded ? all : all.take(_previewCount).toList(growable: false);
    final hasMore = all.length > _previewCount;

    return Column(
      children: [
        ...List.generate(visible.length, (i) {
          final p = visible[i];
          final isFirst = i == 0;
          final isLast = i == visible.length - 1 && (_expanded || !hasMore);

          return _TimelineRow(
            point: p,
            fmtDateTime: widget.fmtDateTime,
            isFirst: isFirst,
            isLast: isLast,
          );
        }),
        if (hasMore && !_expanded)
          InkWell(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.expand_more_rounded,
                      size: 18, color: _kBrand),
                  const SizedBox(width: 4),
                  Text(
                    'Show ${all.length - _previewCount} more points',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _kBrand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasMore && _expanded)
          InkWell(
            onTap: () => setState(() => _expanded = false),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.expand_less_rounded, size: 18, color: _kBrand),
                  SizedBox(width: 4),
                  Text(
                    'Show less',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _kBrand,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Single timeline row ───────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final TrackingPoint point;
  final String Function(String) fmtDateTime;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.point,
    required this.fmtDateTime,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 46,
            child: Column(
              children: [
                // Top connector
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : const Color(0xffD0D7DE),
                  ),
                ),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? _kBrand : const Color(0xffD0D7DE),
                    border: Border.all(
                      color: isFirst ? _kBrand : const Color(0xffAAB2BD),
                      width: 2,
                    ),
                  ),
                ),
                // Bottom connector
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : const Color(0xffD0D7DE),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 6, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFirst
                    ? _kBrand.withValues(alpha: 0.04)
                    : const Color(0xffFAFBFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst
                      ? _kBrand.withValues(alpha: 0.15)
                      : const Color(0xffE8EDEA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp
                  Text(
                    fmtDateTime(point.recordedAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isFirst ? _kBrand : _kMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Coordinates
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14,
                          color: isFirst ? _kBrand : const Color(0xffAAB2BD)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Meta chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (point.speed != null)
                        _MetaChip(
                          icon: Icons.speed_rounded,
                          label: '${point.speed!.toStringAsFixed(1)} m/s',
                        ),
                      if (point.accuracy != null)
                        _MetaChip(
                          icon: Icons.gps_fixed_rounded,
                          label: '±${point.accuracy!.toStringAsFixed(0)}m',
                        ),
                      if (point.bearing != null)
                        _MetaChip(
                          icon: Icons.explore_rounded,
                          label: '${point.bearing!.toStringAsFixed(0)}°',
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
}

// ─── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xffF0F2F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kMuted),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
