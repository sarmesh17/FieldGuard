part of 'routes_screen.dart';

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
            Icon(
              Icons.location_off_outlined,
              color: AppColors.grey,
              size: 34,
            ),
            SizedBox(height: 8),
            Text(
              'Live Tracking is off',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Turn it on from the Home screen to see your route.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
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
              child: Divider(thickness: 3, color: AppColors.grey4),
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
            Icon(
              reached ? Icons.check_circle : Icons.circle,
              size: reached ? 14 : 8,
              color: _kBrand,
            ),
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
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reached ? 'You reached your destination' : task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: reached ? _kBrand : AppColors.grey,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onOpenTask,
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Open Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kBrand),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                label: const Text(
                  'Call Shop',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _kBrand,
                  ),
                ),
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
        Text(
          'NO ACTIVE TASK',
          style: TextStyle(
            color: AppColors.grey,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Showing your current location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Start a task to see the route to its shop here.',
          style: TextStyle(fontSize: 13, color: AppColors.grey),
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
          Text(
            'Arrived',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
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
      final dist = m < 1000
          ? '${m.round()} m'
          : '${(m / 1000).toStringAsFixed(1)} km';
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
          Text(
            _label(),
            style: const TextStyle(
              color: _kBrand,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

