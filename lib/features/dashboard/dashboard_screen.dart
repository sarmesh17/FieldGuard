import 'dart:math' as math;

import 'package:fieldguard/core/router/app_routes.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/dashboard/dashboard_header.dart';
import 'package:fieldguard/features/dashboard/dashboard_provider.dart';
import 'package:fieldguard/features/employee/presentation/screens/create_employee_screen.dart';
import 'package:fieldguard/features/live_tracking/presentation/tracking_controller.dart';
import 'package:fieldguard/features/manager/presentation/screens/create_manager_screen.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand palette (consistent with Team / Routes / Shops / Profile) ─────────
const _kDark = AppColors.green;
const _kPrimary = AppColors.green;
const _kMid = AppColors.green;
const _kSurface = AppColors.background;

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 700;
        final horizontalPadding = isTablet ? 32.0 : 20.0;

        return Scaffold(
          backgroundColor: _kSurface,
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.tasks),
              backgroundColor: _kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: _kPrimary,
            onRefresh: () async {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardTodayTasksProvider);
              ref.invalidate(dashboardUrgentTasksProvider);
              ref.invalidate(dashboardActivityProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 760 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Gradient hero (header + date + progress) ─────────
                      const _HeroSection(),

                      // ── Body sections ────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          22,
                          horizontalPadding,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Live tracking — only renders for field agents.
                            const _AnimatedEntry(
                              index: 0,
                              child: _LiveTrackingCard(),
                            ),
                            const _AnimatedEntry(
                              index: 1,
                              child: _QuickActionsSection(),
                            ),
                            const SizedBox(height: 28),
                            const _AnimatedEntry(
                              index: 2,
                              child: _UrgentTasksSection(),
                            ),
                            const _AnimatedEntry(
                              index: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(text: 'TASKS OVERVIEW'),
                                  SizedBox(height: 16),
                                  _TaskSummarySection(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _AnimatedEntry(
                              index: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(text: 'LIVE TEAM STATUS'),
                                  SizedBox(height: 16),
                                  _TeamStatusSection(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _AnimatedEntry(
                              index: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(text: 'RECENT ACTIVITY'),
                                  SizedBox(height: 16),
                                  _ActivityFeedSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient hero — greeting/avatar/role + today's date + daily progress
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateLine =
        '${DateFormat('EEEE').format(now)}, ${DateFormat('d MMM').format(now)}';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kDark, _kPrimary, _kMid],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -40, right: -30, child: _orb(160, 0.06)),
          Positioned(bottom: -20, left: -30, child: _orb(110, 0.05)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ManagerHeaderSection(),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        dateLine,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: _HeroProgressRings(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

// Frosted card with two circular gradient progress rings (Today + Overall),
// side by side, sitting inside the gradient hero.
class _HeroProgressRings extends ConsumerWidget {
  const _HeroProgressRings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(dashboardTodayTasksProvider).asData?.value;
    final overall = ref.watch(dashboardSummaryProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProgressRingTile(
              label: 'Today',
              completed: today?.completedTasks ?? 0,
              total: today?.totalTasks ?? 0,
              gradient: const [AppColors.yellow, AppColors.orange6],
            ),
          ),
          Container(
            width: 1,
            height: 78,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _ProgressRingTile(
              label: 'Overall',
              completed: overall?.completedTasks ?? 0,
              total: overall?.totalTasks ?? 0,
              gradient: const [AppColors.gradientEnd, AppColors.white16],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingTile extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final List<Color> gradient;

  const _ProgressRingTile({
    required this.label,
    required this.completed,
    required this.total,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                colors: gradient,
                trackColor: Colors.white.withValues(alpha: 0.18),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final List<Color> colors;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    // Start at the top (-90°) and sweep clockwise by the progress fraction.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.colors != colors ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.grey,
        letterSpacing: 1,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered entrance animation — fades + slides each section up in turn.
// ─────────────────────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delayMs = (widget.index.clamp(0, 8)) * 90;
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

// ─────────────────────────────────────────────────────────────────────────────
// Live Tracking toggle (field agents only)
// ─────────────────────────────────────────────────────────────────────────────
class _LiveTrackingCard extends ConsumerWidget {
  const _LiveTrackingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider).asData?.value;
    // Resolve the role from FRESH, per-session sources only — the login state
    // (set this login) primary, the dashboard summary (me.user.role) as a
    // fallback. We deliberately avoid any globally-cached role provider: a
    // stale value from a previous session would flash the card for the wrong
    // role until the fresh data arrives.
    final loginState = ref.watch(loginNotifierProvider);
    final loginRole = loginState is LoginSuccess
        ? loginState.response.user.role.toUpperCase()
        : '';
    final summaryRole = (summary?.role ?? '').toUpperCase();
    final role = loginRole.isNotEmpty ? loginRole : summaryRole;

    // Only managers go to the field, so live tracking is for them only.
    // Admins (office) never broadcast a location — the card is hidden.
    // (Empty role → not yet known → also hidden, so it never flashes.)
    if (role != 'MANAGER') return const SizedBox.shrink();

    final tracking = ref.watch(trackingControllerProvider);
    final active = tracking.active;
    final busy = tracking.busy;

    Future<void> onToggle() async {
      if (busy) return;
      final notifier = ref.read(trackingControllerProvider.notifier);

      if (active) {
        // Warn before turning OFF mid-task — stopping tracking can interrupt
        // automatic geofence visit detection for the active task.
        final hasInProgress = (summary?.inProgressTasks ?? 0) > 0;
        if (hasInProgress) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange3,
                size: 36,
              ),
              title: const Text('Task in progress'),
              content: const Text(
                'You have a task in progress. Turning off live tracking may '
                'stop automatic arrival detection. Turn it off anyway?',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep tracking'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red3,
                  ),
                  child: const Text('Turn off'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
        }
        await notifier.stop();
      } else {
        final ok = await notifier.start();
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for tracking'),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [_kDark, _kPrimary, _kMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Colors.transparent : AppColors.orange,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? _kPrimary.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: active ? 16 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.green6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  active ? Icons.location_on : Icons.location_off_outlined,
                  color: active ? Colors.white : _kPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active
                          ? 'Sharing your live location'
                          : 'Turn on to share your location',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: active
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.grey5,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _kPrimary,
                  ),
                )
              else
                Switch(
                  value: active,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions (Feature 4)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginNotifierProvider);
    final role = loginState is LoginSuccess
        ? loginState.response.user.role.toUpperCase()
        : '';
    final isAdmin = role == 'ADMIN';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.add_task_rounded,
            label: 'New Task',
            color: AppColors.green6,
            iconColor: AppColors.green5,
            onTap: () => context.push(AppRoutes.tasks),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Add Employee',
            color: AppColors.blue8,
            iconColor: AppColors.blue3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
              );
            },
          ),
          if (isAdmin) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.manage_accounts_rounded,
              label: 'Add Manager',
              color: AppColors.white28,
              iconColor: AppColors.pink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateManagerScreen(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.campaign_rounded,
            label: 'Broadcast',
            color: AppColors.white10,
            iconColor: AppColors.red4,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgent Tasks (Feature 1)
// ─────────────────────────────────────────────────────────────────────────────
class _UrgentTasksSection extends ConsumerWidget {
  const _UrgentTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardUrgentTasksProvider);

    return async.when(
      data: (response) {
        if (response.tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(text: 'ACTION REQUIRED'),
            const SizedBox(height: 12),
            ...response.tasks.map(
              (task) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.red7),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.red6,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.red4,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.red13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'High Priority • Assignee: ${task.assignee.fullName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.red10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.red4.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tasks Summary
// ─────────────────────────────────────────────────────────────────────────────
class _TaskSummarySection extends ConsumerWidget {
  const _TaskSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardSummaryProvider);

    return async.when(
      loading: () => const TaskCardsSkeleton(),
      error: (e, stack) => TaskCardsError(
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
      ),
      data: (summary) => Row(
        children: [
          Expanded(
            child: _TaskStatCard(
              icon: Icons.hourglass_top_rounded,
              iconBg: AppColors.orange9,
              iconColor: AppColors.orange3,
              value: summary.pendingTasks,
              label: 'PENDING',
              valueColor: AppColors.orange3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TaskStatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: AppColors.green6,
              iconColor: AppColors.green5,
              value: summary.completedTasks,
              label: 'DONE',
              valueColor: AppColors.green5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TaskStatCard(
              icon: Icons.autorenew_rounded,
              iconBg: AppColors.blue8,
              iconColor: AppColors.blue3,
              value: summary.inProgressTasks,
              label: 'IN PROGRESS',
              valueColor: AppColors.blue3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final int value;
  final String label;
  final Color valueColor;

  const _TaskStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          // scaleDown so big numbers never overflow a narrow card.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // scaleDown keeps multi-word labels ("IN PROGRESS") on one line.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCardsSkeleton extends StatelessWidget {
  const TaskCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.orange),
              ),
              child: const AppShimmer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBox(width: 44, height: 44, radius: 12),
                    SizedBox(height: 12),
                    SkeletonBox(width: 34, height: 28, radius: 8),
                    SizedBox(height: 8),
                    SkeletonBox(width: 56, height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class TaskCardsError extends StatelessWidget {
  final VoidCallback onRetry;
  const TaskCardsError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Could not load tasks',
            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team Status
// ─────────────────────────────────────────────────────────────────────────────
class _TeamStatusSection extends ConsumerWidget {
  const _TeamStatusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardSummaryProvider);

    return async.when(
      loading: () => Column(
        children: const [
          _TeamStatusSkeletonCard(),
          SizedBox(height: 14),
          _TeamStatusSkeletonCard(),
        ],
      ),
      error: (e, stack) => GestureDetector(
        onTap: () => ref.invalidate(dashboardSummaryProvider),
        child: _teamCard(
          dotColor: AppColors.grey,
          title: 'Could not load — tap to retry',
          value: '',
          valueColor: AppColors.grey,
        ),
      ),
      data: (team) => Column(
        children: [
          _teamCard(
            dotColor: AppColors.green5,
            title: 'Online Now',
            value:
                '${team.onlineTeam} ${team.onlineTeam == 1 ? 'Rep' : 'Reps'}',
            valueColor: AppColors.green,
          ),
          const SizedBox(height: 14),
          _teamCard(
            dotColor: AppColors.blue12,
            title: 'Offline',
            value:
                '${team.offlineTeam} ${team.offlineTeam == 1 ? 'Rep' : 'Reps'}',
            valueColor: AppColors.grey25,
          ),
        ],
      ),
    );
  }

  Widget _teamCard({
    required Color dotColor,
    required String title,
    required String value,
    required Color valueColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            trailing
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamStatusSkeletonCard extends StatelessWidget {
  const _TeamStatusSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange),
      ),
      child: const AppShimmer(
        child: Row(
          children: [
            SkeletonBox(width: 12, height: 12, shape: BoxShape.circle),
            SizedBox(width: 16),
            SkeletonBox(width: 120, height: 13),
            Spacer(),
            SkeletonBox(width: 54, height: 13),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Feed (Feature 5)
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityFeedSection extends ConsumerWidget {
  const _ActivityFeedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardActivityProvider);

    return async.when(
      data: (response) {
        if (response.history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No recent activity',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.orange),
          ),
          child: Column(
            children: response.history.map((event) {
              final isLast = response.history.last == event;

              // Determine icon and color based on action
              IconData icon = Icons.info_outline_rounded;
              Color color = AppColors.blue3;

              if (event.action.toUpperCase().contains('CREATE')) {
                icon = Icons.add_circle_outline_rounded;
                color = AppColors.green5;
              } else if (event.action.toUpperCase().contains('UPDATE') ||
                  event.action.toUpperCase().contains('CHANGE')) {
                icon = Icons.edit_note_rounded;
                color = AppColors.orange3;
              } else if (event.action.toUpperCase().contains('COMPLETE')) {
                icon = Icons.check_circle_outline_rounded;
                color = AppColors.green5;
              }

              // Format date (e.g., "10:30 AM")
              final timeString = event.createdAt.isNotEmpty
                  ? DateFormat(
                      'h:mm a',
                    ).format(DateTime.parse(event.createdAt).toLocal())
                  : '';

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(
                      '${event.performer?.fullName ?? "Someone"} ${event.action.replaceAll("_", " ")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.changeReason ??
                            (event.task.title != null
                                ? 'Task: ${event.task.title}'
                                : 'Task ID: ${event.task.id}'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    trailing: Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.grey4,
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Column(
        children: [
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
      error: (e, stack) => const SizedBox.shrink(),
    );
  }
}
