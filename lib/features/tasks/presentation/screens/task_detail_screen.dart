import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

const _kBrand = Color(0xff005C33);
const _kBrandLight = Color(0xff00874C);
const _kInk = Color(0xff0D1B2A);
const _kMuted = Color(0xff8A94A6);
const _kBg = Color(0xffF2F4F7);

/// Full task view. The list screen only has summary data, so on tap we
/// fetch the complete record from `GET /api/v1/tasks/:id` via
/// [taskDetailProvider] (keyed by task id, auto-disposed).
class TaskDetailScreen extends ConsumerWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(taskDetailProvider(taskId));

    return Scaffold(
      backgroundColor: _kBg,
      body: detail.when(
        loading: () => const _LoadingSkeleton(),
        error: (_, _) => _DetailScaffold(
          child: _ErrorView(
            onRetry: () => ref.invalidate(taskDetailProvider(taskId)),
          ),
        ),
        data: (response) => _TaskDetailBody(task: response.task),
      ),
    );
  }
}

/// Minimal scaffold (just a back button) used on error, before we know
/// the task title.
class _DetailScaffold extends StatelessWidget {
  final Widget child;

  const _DetailScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: _kInk,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _TaskDetailBody extends StatefulWidget {
  final TaskData task;

  const _TaskDetailBody({required this.task});

  @override
  State<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends State<_TaskDetailBody>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Staggered fade + rise so the sections cascade in on open.
  Widget _stagger(int i, Widget child) {
    final start = (0.06 * i).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final sections = <Widget>[
      _StatusTrackerCard(task: task),
      const SizedBox(height: 18),
      if (task.description.isNotEmpty) ...[
        _LabeledCard(
          icon: Icons.notes_rounded,
          title: 'Description',
          child: Text(
            task.description,
            style: const TextStyle(
                fontSize: 14, height: 1.55, color: Color(0xff394452)),
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (task.items.isNotEmpty) ...[
        _LabeledCard(
          icon: Icons.checklist_rounded,
          title: 'Checklist',
          trailing: _CountPill(count: task.items.length),
          child: Column(
            children: [
              for (var i = 0; i < task.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 18, color: Color(0xffF0F2F5)),
                _ChecklistItem(text: task.items[i], index: i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      _LocationCard(
        latitude: task.shopLatitude,
        longitude: task.shopLongitude,
      ),
      _LabeledCard(
        icon: Icons.groups_rounded,
        title: 'People',
        child: Column(
          children: [
            _PersonRow(
              icon: Icons.person_rounded,
              role: 'Assignee',
              name: task.assignee.fullName,
              subtitle: task.assignee.employeeCode,
            ),
            const Divider(height: 22, color: Color(0xffF0F2F5)),
            _PersonRow(
              icon: Icons.edit_note_rounded,
              role: 'Created by',
              name: task.creator.fullName,
              subtitle: null,
            ),
            if (task.manager != null) ...[
              const Divider(height: 22, color: Color(0xffF0F2F5)),
              _PersonRow(
                icon: Icons.shield_moon_rounded,
                role: 'Manager',
                name: task.manager!.fullName,
                subtitle: task.manager!.managerCode,
              ),
            ],
          ],
        ),
      ),
      if (task.remarks != null && task.remarks!.isNotEmpty) ...[
        const SizedBox(height: 14),
        _LabeledCard(
          icon: Icons.sticky_note_2_rounded,
          title: 'Remarks',
          child: Text(
            task.remarks!,
            style: const TextStyle(
                fontSize: 14, height: 1.55, color: Color(0xff394452)),
          ),
        ),
      ],
      const SizedBox(height: 14),
      _TimelineCard(task: task),
      const SizedBox(height: 36),
    ];

    return CustomScrollView(
      slivers: [
        _DetailAppBar(task: task),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _stagger(i, sections[i]),
              childCount: sections.length,
            ),
          ),
        ),
      ],
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
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff003D22), _kBrandLight],
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
            const _CancelledState()
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
                  color: reached ? null : const Color(0xffEDF0F3),
                  border: Border.all(
                    color: reached
                        ? Colors.transparent
                        : const Color(0xffDCE1E7),
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
                  color: reached ? Colors.white : const Color(0xffAAB2BD),
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
            Container(height: 5, color: const Color(0xffE9EDF1)),
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
  const _CancelledState();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xffFF3347);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [red.withValues(alpha: 0.10), red.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: red.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.cancel_rounded, color: red, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Cancelled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: red,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'This task is no longer active.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xff8A7178)),
                ),
              ],
            ),
          ),
        ],
      ),
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
              color: Color(0xff5A6472),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location ─────────────────────────────────────────────────────────────────

/// Shop coordinates arrive from the API as strings (DB decimal), so we
/// `double.tryParse` (the Dart equivalent of parseFloat) before showing
/// them. If either value is missing or unparseable we hide the card.
class _LocationCard extends StatelessWidget {
  final String? latitude;
  final String? longitude;

  const _LocationCard({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final lat = latitude == null ? null : double.tryParse(latitude!);
    final lng = longitude == null ? null : double.tryParse(longitude!);

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

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final TaskData task;

  const _TimelineCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final events = <(String, String, IconData)>[
      ('Created', _formatDateTime(task.createdAt), Icons.add_circle_outline_rounded),
      ('Last updated', _formatDateTime(task.updatedAt), Icons.update_rounded),
      if (task.completedAt != null)
        ('Completed', _formatDateTime(task.completedAt!),
            Icons.task_alt_rounded),
    ];

    return _LabeledCard(
      icon: Icons.history_rounded,
      title: 'Activity',
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _TimelineRow(
              label: events[i].$1,
              value: events[i].$2,
              icon: events[i].$3,
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBrand.withValues(alpha: 0.10),
                ),
                child: Icon(icon, size: 15, color: _kBrand),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xffEAEEF2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ],
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
                color: Color(0xff394452),
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
                color: Color(0xff5A6472),
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
              colors: [Color(0xff003D22), _kBrandLight],
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
            baseColor: const Color(0xffE7EBEF),
            highlightColor: const Color(0xffF6F8FA),
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
                color: const Color(0xffFF3347).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 38, color: Color(0xffFF3347)),
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
      'PENDING' => const Color(0xffF59E0B),
      'IN_PROGRESS' => const Color(0xff3B82F6),
      'COMPLETED' => const Color(0xff22C55E),
      'CANCELLED' => const Color(0xffFF3347),
      _ => const Color(0xffB0B7C3),
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

String _formatDateTime(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(isoDate)} · $h:$m $ap';
  } catch (_) {
    return isoDate;
  }
}
