part of 'task_detail_screen.dart';

// ─── Shop / Location ──────────────────────────────────────────────────────────

/// Shows the linked shop (name + image + address) when present. Falls back
/// to raw coordinates for legacy tasks created before the shopId migration —
/// those don't carry a `shop` object, only the coordinates that were
/// captured at the time. Shop coordinates arrive as DB-decimal strings, so
/// we `double.tryParse` before formatting them.
class _ShopCard extends StatelessWidget {
  final TaskShop? shop;
  final String? legacyLatitude;
  final String? legacyLongitude;

  const _ShopCard({
    required this.shop,
    required this.legacyLatitude,
    required this.legacyLongitude,
  });

  @override
  Widget build(BuildContext context) {
    if (shop != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _LabeledCard(
          icon: Icons.storefront_rounded,
          title: 'Shop',
          child: _ShopBody(shop: shop!),
        ),
      );
    }

    final lat = legacyLatitude == null ? null : double.tryParse(legacyLatitude!);
    final lng = legacyLongitude == null ? null : double.tryParse(legacyLongitude!);
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _LabeledCard(
        icon: Icons.place_rounded,
        title: 'Shop Location',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kBrand.withValues(alpha: 0.08),
                _kBrandLight.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kBrand, _kBrandLight],
                  ),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legacy task — no shop linked',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _kMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CoordLine(label: 'LAT', value: lat.toStringAsFixed(5)),
                    const SizedBox(height: 4),
                    _CoordLine(label: 'LNG', value: lng.toStringAsFixed(5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopBody extends StatelessWidget {
  final TaskShop shop;

  const _ShopBody({required this.shop});

  @override
  Widget build(BuildContext context) {
    final hasImage = shop.shopImage != null && shop.shopImage!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kBrand.withValues(alpha: 0.08),
            _kBrandLight.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.white,
              child: hasImage
                  ? Image.network(
                      shop.shopImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.store_rounded,
                        color: _kBrand,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.store_rounded,
                      color: _kBrand,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                if (shop.address != null && shop.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shop.address!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.grey10,
                      height: 1.35,
                    ),
                  ),
                ],
                if (shop.latitude != null && shop.longitude != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${shop.latitude}, ${shop.longitude}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _kMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordLine extends StatelessWidget {
  final String label;
  final String value;

  const _CoordLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _kBrand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _kBrand,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kInk,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Geofence Visits ──────────────────────────────────────────────────────────

/// Timeline of geofence visits for the task (enter-time ascending), rendered
/// as a vertical list of entry → exit cards. Each shows the stay duration and
/// flags exits the system had to estimate.
class _VisitsCard extends StatelessWidget {
  final List<TaskGeofenceVisit> visits;

  const _VisitsCard({required this.visits});

  @override
  Widget build(BuildContext context) {
    return _LabeledCard(
      icon: Icons.pin_drop_rounded,
      title: 'Visits',
      trailing: _CountPill(count: visits.length),
      child: Column(
        children: [
          for (var i = 0; i < visits.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _VisitRow(visit: visits[i], index: i),
          ],
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  final TaskGeofenceVisit visit;
  final int index;

  const _VisitRow({required this.visit, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _kBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kBrand, _kBrandLight],
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _DurationPill(seconds: visit.stayDurationSeconds),
              const Spacer(),
              if (visit.exitEstimated) const _ApproxBadge(),
            ],
          ),
          const SizedBox(height: 12),
          _VisitStop(
            icon: Icons.login_rounded,
            label: 'Entered',
            time: visit.enteredAt,
            lat: visit.enterLatitude,
            lng: visit.enterLongitude,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11, top: 2, bottom: 2),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(
                width: 2,
                thickness: 2,
                color: AppColors.blue14,
              ),
            ),
          ),
          _VisitStop(
            icon: Icons.logout_rounded,
            label: 'Exited',
            time: visit.exitedAt,
            lat: visit.exitLatitude,
            lng: visit.exitLongitude,
          ),
        ],
      ),
    );
  }
}

/// One end of a visit (enter or exit): local time plus the captured coords.
class _VisitStop extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime time;
  final double lat;
  final double lng;

  const _VisitStop({
    required this.icon,
    required this.label,
    required this.time,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _kBrand),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(time),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  final int seconds;

  const _DurationPill({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kBrand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: _kBrand),
          const SizedBox(width: 5),
          Text(
            _formatDuration(seconds),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kBrand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when an exit was estimated rather than cleanly observed.
class _ApproxBadge extends StatelessWidget {
  const _ApproxBadge();

  static const _amber = AppColors.brown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange2.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 12, color: _amber),
          SizedBox(width: 4),
          Text(
            '~approx exit',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable building blocks ─────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _kBrand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: _kBrand),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kInk,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _LabeledCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _LabeledCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionHeading(icon: icon, title: title),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kBrand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kBrand,
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  final int index;

  const _ChecklistItem({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _kBrand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kBrand,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.blue4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final IconData icon;
  final String role;
  final String name;
  final String? subtitle;

  const _PersonRow({
    required this.icon,
    required this.role,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kBrand.withValues(alpha: 0.14),
                _kBrandLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _kBrand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.grey10,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _capitalise(priority),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h, {double? w, double r = 16}) => Container(
          width: w ?? double.infinity,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 188,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.green16, _kBrandLight],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.white11,
            highlightColor: AppColors.white14,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              children: [
                box(150, r: 20),
                const SizedBox(height: 16),
                box(90, r: 20),
                const SizedBox(height: 14),
                box(120, r: 20),
                const SizedBox(height: 14),
                box(150, r: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.red5.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 38, color: AppColors.red5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load task',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Something went wrong while fetching the task details.',
              style: TextStyle(fontSize: 13, color: _kMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(String status) => switch (status.toUpperCase()) {
      'PENDING' => AppColors.orange2,
      'IN_PROGRESS' => AppColors.blue3,
      'COMPLETED' => AppColors.green5,
      'CANCELLED' => AppColors.red5,
      _ => AppColors.grey9,
    };

IconData _statusIcon(String status) => switch (status.toUpperCase()) {
      'PENDING' => Icons.hourglass_top_rounded,
      'IN_PROGRESS' => Icons.bolt_rounded,
      'COMPLETED' => Icons.verified_rounded,
      'CANCELLED' => Icons.cancel_rounded,
      _ => Icons.help_outline_rounded,
    };

String _statusLabel(String status) => switch (status.toUpperCase()) {
      'IN_PROGRESS' => 'In Progress',
      _ => _capitalise(status),
    };

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// `May 24, 9:00 AM` — date dropped to the day, time to the minute. Input is
/// converted to local before formatting.
String _formatDateTime(DateTime utc) {
  final dt = utc.toLocal();
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final meridiem = dt.hour < 12 ? 'AM' : 'PM';
  return '${_months[dt.month - 1]} ${dt.day}, $hour12:$minute $meridiem';
}

/// Compact human duration: `45s`, `12m`, `1h 18m`. Visit durations are
/// client-authoritative seconds (kept as sent, even for estimated exits).
String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final remMinutes = minutes % 60;
  return remMinutes == 0 ? '${hours}h' : '${hours}h ${remMinutes}m';
}

