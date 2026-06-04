part of 'task_detail_screen.dart';

// ─── Track Live ───────────────────────────────────────────────────────────────

class _TrackLiveButton extends StatelessWidget {
  final TaskData task;

  const _TrackLiveButton({required this.task});

  @override
  Widget build(BuildContext context) {
    // The assignee's destination — prefer the linked shop's coords, fall back
    // to the legacy raw ones. Passed to the tracking screen so it can drop a
    // destination pin + draw the driving route alongside the live pin.
    final shopLat =
        double.tryParse(task.shop?.latitude ?? task.shopLatitude ?? '');
    final shopLng =
        double.tryParse(task.shop?.longitude ?? task.shopLongitude ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskLiveTrackingScreen(
              taskId: task.id,
              employeeId: task.assignee.id,
              taskTitle: task.title,
              employeeName: task.assignee.fullName,
              shopLatitude: shopLat,
              shopLongitude: shopLng,
              shopName: task.shop?.name,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kBrand, _kBrandLight],
            ),
            boxShadow: [
              BoxShadow(
                color: _kBrand.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Follow ${task.assignee.fullName} on the map',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final TaskData task;

  const _DetailAppBar({required this.task});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 188,
      pinned: true,
      backgroundColor: _kBrand,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          tooltip: 'Task history',
          icon: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskHistoryScreen(
                taskId: task.id,
                taskTitle: task.title,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.green16, _kBrandLight],
                ),
              ),
            ),
            // Soft decorative orbs.
            Positioned(
              top: -40,
              right: -30,
              child: _orb(150, 0.06),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: _orb(110, 0.05),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(status: task.status),
                        const SizedBox(width: 8),
                        _PriorityBadge(priority: task.priority),
                        const Spacer(),
                        Text(
                          '#${task.id}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

// ─── Status Tracker (Amazon-style) ────────────────────────────────────────────

class _StatusTrackerCard extends StatelessWidget {
  final TaskData task;

  const _StatusTrackerCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isCancelled = task.status.toUpperCase() == 'CANCELLED';
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionHeading(
                icon: Icons.local_shipping_rounded,
                title: 'Task Progress',
              ),
              const Spacer(),
              _DueChip(dueDate: task.dueDate),
            ],
          ),
          const SizedBox(height: 20),
          if (isCancelled)
            _CancelledState(task: task)
          else
            _StatusStepper(status: task.status),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatefulWidget {
  final String status;

  const _StatusStepper({required this.status});

  @override
  State<_StatusStepper> createState() => _StatusStepperState();
}

class _StatusStepperState extends State<_StatusStepper>
    with TickerProviderStateMixin {
  static const _steps = [
    ('Pending', Icons.schedule_rounded),
    ('In Progress', Icons.bolt_rounded),
    ('Completed', Icons.verified_rounded),
  ];

  late final AnimationController _fill;
  late final AnimationController _pulse;

  int get _currentIndex => switch (widget.status.toUpperCase()) {
        'PENDING' => 0,
        'IN_PROGRESS' => 1,
        'COMPLETED' => 2,
        _ => 0,
      };

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    // Let the screen settle, then animate the line filling up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fill.forward();
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = _currentIndex / (_steps.length - 1); // 0, 0.5, 1
    final curved = CurvedAnimation(parent: _fill, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: Listenable.merge([curved, _pulse]),
      builder: (context, _) {
        final progress = curved.value * target;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  _StepNode(
                    label: _steps[i].$1,
                    icon: _steps[i].$2,
                    // A node lights up once the fill line reaches it.
                    filled: progress >= (i / 2) - 0.001,
                    isDone: i < _currentIndex,
                    isCurrent: i == _currentIndex,
                    pulse: _pulse.value,
                  ),
                  if (i < _steps.length - 1)
                    Expanded(
                      child: _Connector(
                        fraction:
                            ((progress - i * 0.5) / 0.5).clamp(0.0, 1.0),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ProgressCaption(
              status: widget.status,
              progress: curved.value * (_currentIndex / 2),
            ),
          ],
        );
      },
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isDone;
  final bool isCurrent;
  final double pulse;

  const _StepNode({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isDone,
    required this.isCurrent,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const active = _kBrand;
    final reached = filled || isDone || isCurrent;

    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing halo on the current step.
              if (isCurrent)
                Container(
                  width: 44 + pulse * 12,
                  height: 44 + pulse * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active.withValues(alpha: 0.18 * (1 - pulse)),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: reached
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_kBrand, _kBrandLight],
                        )
                      : null,
                  color: reached ? null : AppColors.white20,
                  border: Border.all(
                    color: reached
                        ? Colors.transparent
                        : AppColors.grey31,
                    width: 1.5,
                  ),
                  boxShadow: reached
                      ? [
                          BoxShadow(
                            color: active.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : icon,
                  size: 20,
                  color: reached ? Colors.white : AppColors.grey11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: reached ? _kInk : _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final double fraction;

  const _Connector({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Align with the vertical centre of the 40px node circles.
      padding: const EdgeInsets.only(top: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(height: 5, color: AppColors.white9),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kBrand, _kBrandLight],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCaption extends StatelessWidget {
  final String status;
  final double progress;

  const _ProgressCaption({required this.status, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kBrand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), size: 16, color: _kBrand),
          const SizedBox(width: 8),
          Text(
            _captionFor(status),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _kBrand,
            ),
          ),
          const Spacer(),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _kBrand,
            ),
          ),
        ],
      ),
    );
  }

  String _captionFor(String s) => switch (s.toUpperCase()) {
        'PENDING' => 'Waiting to be picked up',
        'IN_PROGRESS' => 'Work is underway',
        'COMPLETED' => 'All done — task completed',
        _ => _statusLabel(s),
      };
}

class _CancelledState extends StatelessWidget {
  final TaskData task;

  const _CancelledState({required this.task});

  static const _red = AppColors.red5;

  static String _reasonLabel(String? raw) => switch (raw) {
        'SHOP_CLOSED' => 'Shop Closed',
        'SHOP_RELOCATED' => 'Shop Relocated',
        'SHOP_PERMANENTLY_CLOSED' => 'Shop Permanently Closed',
        'SHOP_NOT_FOUND' => 'Shop Not Found',
        'OTHER' => 'Other',
        _ => 'Unknown Reason',
      };

  @override
  Widget build(BuildContext context) {
    final reasonLabel = task.cancelReason != null
        ? _reasonLabel(task.cancelReason)
        : null;
    final hasImage = task.cancelImage != null && task.cancelImage!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                _red.withValues(alpha: 0.10),
                _red.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: _red.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _red.withValues(alpha: 0.15),
                ),
                child:
                    const Icon(Icons.cancel_rounded, color: _red, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Cancelled',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reasonLabel != null
                          ? 'Reason: $reasonLabel'
                          : 'This task is no longer active.',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.grey26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              task.cancelImage!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 180,
                color: _red.withValues(alpha: 0.06),
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: _red, size: 32),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DueChip extends StatelessWidget {
  final String dueDate;

  const _DueChip({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_rounded, size: 13, color: _kMuted),
          const SizedBox(width: 5),
          Text(
            _formatDate(dueDate),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.grey10,
            ),
          ),
        ],
      ),
    );
  }
}

