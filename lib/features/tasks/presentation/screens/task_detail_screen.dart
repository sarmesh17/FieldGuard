import 'dart:io';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/dashboard/dashboard_provider.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';
import 'package:fieldguard/features/tasks/data/dto/update_task_request.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_history_screen.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_live_tracking_screen.dart';
import 'package:fieldguard/features/collections/presentation/screens/collect_payment_screen.dart';
import 'package:fieldguard/features/routes/presentation/providers/navigate_target_provider.dart';
import 'package:fieldguard/features/uploads/image_upload_service.dart';
import 'package:fieldguard/core/router/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        data: (response) {
          // Only ADMIN / MANAGER may live-track an assignee (the spec's
          // "viewers"); an EMPLOYEE viewing their own task can't.
          final login = ref.watch(loginNotifierProvider);
          final role = login is LoginSuccess
              ? login.response.user.role.toUpperCase()
              : '';
          final canTrack = role == 'ADMIN' || role == 'MANAGER';
          return _TaskDetailBody(task: response.task, canTrack: canTrack);
        },
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

class _TaskDetailBody extends ConsumerStatefulWidget {
  final TaskData task;
  final bool canTrack;

  const _TaskDetailBody({required this.task, required this.canTrack});

  @override
  ConsumerState<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends ConsumerState<_TaskDetailBody>
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

  bool _canUpdate(String status) {
    final s = status.toUpperCase();
    return s == 'PENDING' || s == 'IN_PROGRESS';
  }

  /// The task's shop coordinates, preferring the linked shop's and falling
  /// back to the legacy raw coordinates. Null when neither is parseable —
  /// then there's nothing to navigate to.
  ({double lat, double lng})? _navCoords(TaskData task) {
    final lat = double.tryParse(task.shop?.latitude ?? task.shopLatitude ?? '');
    final lng =
        double.tryParse(task.shop?.longitude ?? task.shopLongitude ?? '');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// Logged-in user's role (`ADMIN` / `MANAGER` / `EMPLOYEE`), or empty
  /// string when the session is somehow unresolved. Matches the same lookup
  /// the outer [TaskDetailScreen] uses for [canTrack].
  String _userRole() {
    final login = ref.read(loginNotifierProvider);
    return login is LoginSuccess
        ? login.response.user.role.toUpperCase()
        : '';
  }

  /// Opens the collection form for this task's shop. The collection endpoint
  /// is task-independent (only needs shopId), so we pass through from the
  /// linked shop directly.
  void _collectPayment(TaskData task) {
    final shop = task.shop;
    if (shop == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectPaymentScreen(
          shopId: shop.id,
          shopName: shop.name,
        ),
      ),
    );
  }

  /// Sets the navigation target and switches to the Routes tab, which draws
  /// the driving route to this task's shop. The shop's own 20 m geofence is
  /// armed separately by [AutoGeofenceService] for any IN_PROGRESS task, so
  /// enter/stay/exit is recorded regardless of whether the user taps this.
  void _navigateToShop(TaskData task) {
    final c = _navCoords(task);
    if (c == null) return;
    ref.read(navigateTargetProvider.notifier).state = NavigateTarget(
      taskId: task.id,
      lat: c.lat,
      lng: c.lng,
      shopName: task.shop?.name ?? task.title,
      address: task.shop?.address,
    );
    // Pop the imperative MaterialPageRoute (TaskDetailScreen) first, so we
    // actually reveal the root tab underneath. Otherwise if we're already on
    // the Routes tab, go_router does nothing and the detail screen stays up.
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.go(AppRoutes.routes);
  }

  Future<void> _showUpdateSheet(TaskData task) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateTaskSheet(task: task),
    );
    if (updated == true && mounted) {
      ref.invalidate(taskDetailProvider(task.id));
      // Refresh the shared task list + dashboard so the new status shows even
      // when the user returns via the system back button (which carries no
      // result to react to). Without this the list stays stale until it's
      // re-fetched some other way (e.g. switching tabs).
      ref.read(tasksNotifierProvider.notifier).reload();
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(dashboardTodayTasksProvider);
      ref.invalidate(dashboardUrgentTasksProvider);
      ref.invalidate(dashboardActivityProvider);
    }
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
      if (widget.canTrack &&
          task.status.toUpperCase() == 'IN_PROGRESS') ...[
        const SizedBox(height: 14),
        _TrackLiveButton(task: task),
      ],
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
      _ShopCard(
        shop: task.shop,
        legacyLatitude: task.shopLatitude,
        legacyLongitude: task.shopLongitude,
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
      if (task.geofenceVisits.isNotEmpty) ...[
        const SizedBox(height: 14),
        _VisitsCard(visits: task.geofenceVisits),
      ],
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
      const SizedBox(height: 36),
    ];

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        CustomScrollView(
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
        ),
        Positioned(
          bottom: bottomPad + 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (task.status.toUpperCase() == 'IN_PROGRESS' &&
                  _navCoords(task) != null) ...[
                _NavigateFab(onTap: () => _navigateToShop(task)),
                const SizedBox(height: 12),
              ],
              // Collect Payment: IN_PROGRESS + shop linked + not ADMIN
              // (server returns 403 for ADMIN; this matches that scope).
              if (task.status.toUpperCase() == 'IN_PROGRESS' &&
                  task.shop != null &&
                  _userRole() != 'ADMIN') ...[
                _CollectPaymentFab(onTap: () => _collectPayment(task)),
                const SizedBox(height: 12),
              ],
              if (_canUpdate(task.status))
                _UpdateFab(onTap: () => _showUpdateSheet(task)),
            ],
          ),
        ),
      ],
    );
  }
}

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
  final TaskData task;

  const _CancelledState({required this.task});

  static const _red = Color(0xffFF3347);

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
                          fontSize: 12.5, color: Color(0xff8A7178)),
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
              color: Color(0xff5A6472),
            ),
          ),
        ],
      ),
    );
  }
}

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
                      color: Color(0xff5A6472),
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
                color: Color(0xffD7DDE4),
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

  static const _amber = Color(0xffB7791F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffF59E0B).withValues(alpha: 0.14),
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

// ─── Navigate FAB ─────────────────────────────────────────────────────────────

/// Switches to the Routes tab to draw the driving route to this task's shop.
/// White pill so it reads as secondary to the brand-coloured Update FAB above
/// which it sits.
class _NavigateFab extends StatelessWidget {
  final VoidCallback onTap;

  const _NavigateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, color: _kBrand, size: 18),
              SizedBox(width: 8),
              Text(
                'Navigate',
                style: TextStyle(
                  color: _kBrand,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collect Payment FAB ──────────────────────────────────────────────────────

/// Amber FAB so it reads as a distinct action from the white Navigate and
/// brand-green Update buttons it sits with. Same `field_guard_re` colour
/// language so designs stay consistent across the two apps.
class _CollectPaymentFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CollectPaymentFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xffB45309);
    return Material(
      color: amber,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: amber.withValues(alpha: 0.40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Collect Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update FAB ───────────────────────────────────────────────────────────────

class _UpdateFab extends StatelessWidget {
  final VoidCallback onTap;

  const _UpdateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBrand,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: _kBrand.withValues(alpha: 0.40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Update',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update Task Sheet ────────────────────────────────────────────────────────

class _UpdateTaskSheet extends ConsumerStatefulWidget {
  final TaskData task;

  const _UpdateTaskSheet({required this.task});

  @override
  ConsumerState<_UpdateTaskSheet> createState() => _UpdateTaskSheetState();
}

class _UpdateTaskSheetState extends ConsumerState<_UpdateTaskSheet> {
  late String _selectedStatus;
  CancelReason? _cancelReason;
  final _changeReasonCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String? _imagePath;
  String? _imageKey;
  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0.0;
  bool _submitting = false;
  String? _errorMessage;

  late final ImageUploadService _uploadService;

  static const _statuses = [
    ('PENDING', 'Pending', Color(0xffF59E0B)),
    ('IN_PROGRESS', 'In Progress', Color(0xff3B82F6)),
    ('COMPLETED', 'Completed', Color(0xff22C55E)),
    ('CANCELLED', 'Cancelled', Color(0xff6B7280)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status.toUpperCase();
    _remarksCtrl.text = widget.task.remarks ?? '';
    _uploadService = ImageUploadService(DioClient.createDio());
  }

  @override
  void dispose() {
    _changeReasonCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _onStatusTap(String status) {
    _changeReasonCtrl.clear();
    setState(() {
      _selectedStatus = status;
      _cancelReason = null;
      _imagePath = null;
      _imageKey = null;
      _uploadStatus = UploadStatus.idle;
      _errorMessage = null;
    });
  }

  void _onReasonTap(CancelReason reason) {
    setState(() {
      _cancelReason = reason;
      _imagePath = null;
      _imageKey = null;
      _uploadStatus = UploadStatus.idle;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    setState(() {
      _imagePath = path;
      _imageKey = null;
      _uploadStatus = UploadStatus.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
    try {
      final res = await _uploadService.upload(
        filePath: path,
        category: 'cancel',
        entityId: widget.task.id,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      setState(() {
        _imageKey = res.imageKey;
        _uploadStatus = UploadStatus.done;
      });
    } catch (_) {
      setState(() {
        _uploadStatus = UploadStatus.error;
        _errorMessage = 'Image upload failed. Tap to retry.';
      });
    }
  }

  Future<void> _submit() async {
    final isCancelling = _selectedStatus == 'CANCELLED';
    final isReopening = _selectedStatus == 'PENDING' &&
        widget.task.status.toUpperCase() == 'IN_PROGRESS';

    if (isCancelling) {
      final reason = _cancelReason;
      if (reason == null) {
        setState(() => _errorMessage = 'Please select a cancel reason.');
        return;
      }
      if (reason.requiresPhoto && _imageKey == null) {
        setState(() => _errorMessage = 'Please attach a cancel photo.');
        return;
      }
      if (reason.requiresChangeReason &&
          _changeReasonCtrl.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please describe the reason.');
        return;
      }
    }

    if (isReopening && _changeReasonCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for reopening.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final reason = _cancelReason;

    final request = UpdateTaskRequest(
      status: _selectedStatus,
      remarks: _remarksCtrl.text.trim().isNotEmpty
          ? _remarksCtrl.text.trim()
          : null,
      cancelReason: isCancelling ? reason?.value : null,
      cancelImage:
          (isCancelling && reason != null && reason.requiresPhoto)
              ? _imageKey
              : null,
      changeReason: isCancelling && reason != null && reason.requiresChangeReason
          ? _changeReasonCtrl.text.trim()
          : isReopening
              ? _changeReasonCtrl.text.trim()
              : null,
    );

    final usecase = ref.read(updateTaskUsecaseProvider);
    final result = await usecase(widget.task.id, request);

    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.pop(context, true);
      case Failure(:final exception):
        setState(() {
          _submitting = false;
          _errorMessage = exception.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isCancelling = _selectedStatus == 'CANCELLED';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + kb),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffE0E4EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: _kBrand, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Update Task',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0D1B2A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Status ──────────────────────────────────────────────────────
            const Text(
              'Status',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0D1B2A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final (value, label, color) = s;
                final selected = _selectedStatus == value;
                return _Chip(
                  label: label,
                  selected: selected,
                  selectedColor: color,
                  onTap: () => _onStatusTap(value),
                );
              }).toList(),
            ),

            // ── Cancel Reason ────────────────────────────────────────────────
            if (isCancelling) ...[
              const SizedBox(height: 18),
              const Text(
                'Cancel Reason *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0D1B2A)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CancelReason.values.map((r) {
                  final selected = _cancelReason == r;
                  return _Chip(
                    label: r.chipLabel,
                    selected: selected,
                    selectedColor: const Color(0xffEF4444),
                    onTap: () => _onReasonTap(r),
                  );
                }).toList(),
              ),

              // ── Cancel Photo ─────────────────────────────────────────────
              if (_cancelReason != null &&
                  _cancelReason!.requiresPhoto) ...[
                const SizedBox(height: 18),
                const Text(
                  'Cancel Photo *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0D1B2A)),
                ),
                const SizedBox(height: 10),
                _ImagePickerSection(
                  imagePath: _imagePath,
                  uploadStatus: _uploadStatus,
                  uploadProgress: _uploadProgress,
                  onTap: _uploadStatus == UploadStatus.uploading
                      ? null
                      : _pickImage,
                ),
              ],

              // ── Change Reason (OTHER) ────────────────────────────────────
              if (_cancelReason == CancelReason.other) ...[
                const SizedBox(height: 18),
                const Text(
                  'Reason *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0D1B2A)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _changeReasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the reason…',
                    hintStyle: const TextStyle(
                        fontSize: 13.5, color: Color(0xffB0B7C3)),
                    filled: true,
                    fillColor: const Color(0xffF2F4F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ],

            // ── Reopen Reason ─────────────────────────────────────────────────
            if (_selectedStatus == 'PENDING' &&
                widget.task.status.toUpperCase() == 'IN_PROGRESS') ...[
              const SizedBox(height: 18),
              const Text(
                'Reason for Reopening *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0D1B2A)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _changeReasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Why is this task being reopened?',
                  hintStyle: const TextStyle(
                      fontSize: 13.5, color: Color(0xffB0B7C3)),
                  filled: true,
                  fillColor: const Color(0xffF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],

            // ── Remarks ──────────────────────────────────────────────────────
            const SizedBox(height: 18),
            const Text(
              'Remarks (optional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0D1B2A)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remarksCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any remarks…',
                hintStyle: const TextStyle(
                    fontSize: 13.5, color: Color(0xffB0B7C3)),
                filled: true,
                fillColor: const Color(0xffF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xffEF4444)),
              ),
            ],

            const SizedBox(height: 24),
            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xffE0E4EA)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff6B7280)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? selectedColor
              : const Color(0xffF2F4F7),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xffE0E4EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : const Color(0xff6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final String? imagePath;
  final UploadStatus uploadStatus;
  final double uploadProgress;
  final VoidCallback? onTap;

  const _ImagePickerSection({
    required this.imagePath,
    required this.uploadStatus,
    required this.uploadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: hasImage ? 160 : 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xffF2F4F7),
          border: Border.all(
            color: const Color(0xffE0E4EA),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath!), fit: BoxFit.cover),
                  if (uploadStatus == UploadStatus.uploading)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: uploadProgress,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (uploadStatus == UploadStatus.done)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xff22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_rounded,
                      size: 26, color: Color(0xffB0B7C3)),
                  SizedBox(height: 6),
                  Text(
                    'Attach cancel photo (required)',
                    style: TextStyle(
                        fontSize: 12.5, color: Color(0xff8A94A6)),
                  ),
                ],
              ),
      ),
    );
  }
}

