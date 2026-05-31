import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldguard/features/routes/presentation/providers/route_tasks_provider.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_detail_screen.dart';

/// "Today's Schedule" — today's tasks, active-first then by due time. Driven
/// by [todayTasksProvider]; tapping a row opens the task detail.
class ScheduleList extends ConsumerWidget {
  const ScheduleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider);
    if (tasks.isEmpty) return const _EmptyRow();
    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++)
          _ScheduleEntry(
            index: i,
            child: _ScheduleItem(task: tasks[i], index: i + 1),
          ),
      ],
    );
  }
}

/// Fades + slides each schedule row in with a small per-index delay, so the
/// list cascades nicely instead of popping in all at once.
class _ScheduleEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _ScheduleEntry({required this.index, required this.child});

  @override
  State<_ScheduleEntry> createState() => _ScheduleEntryState();
}

class _ScheduleEntryState extends State<_ScheduleEntry>
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

class _ScheduleItem extends StatelessWidget {
  final TaskSummary task;
  final int index;

  const _ScheduleItem({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = _ThemeFor(task.status);
    final due = DateTime.tryParse(task.dueDate)?.toLocal();
    final timeText = due == null ? '' : _formatTime(due);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(16),
            border: theme.borderColor == null
                ? null
                : Border.all(color: theme.borderColor!, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.avatarBackground,
                child: theme.avatarIcon != null
                    ? Icon(theme.avatarIcon, color: theme.avatarFg, size: 18)
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: theme.avatarFg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: theme.titleStrike
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: theme.titleColor,
                        decoration: theme.titleStrike
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          theme.subtitleIcon,
                          size: 14,
                          color: theme.subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          theme.subtitle(timeText),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.subtitleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.chevronColor),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $meridiem';
  }
}

// ── Visual themes per status ──────────────────────────────────────────────────

class _ThemeFor {
  final Color background;
  final Color? borderColor;
  final Color avatarBackground;
  final Color avatarFg;
  final IconData? avatarIcon;
  final Color titleColor;
  final bool titleStrike;
  final IconData subtitleIcon;
  final Color subtitleColor;
  final Color chevronColor;
  final String Function(String time) subtitle;

  factory _ThemeFor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return _ThemeFor._(
          background: Colors.white,
          borderColor: const Color(0xFF0E5A3B),
          avatarBackground: const Color(0xFF0E5A3B),
          avatarFg: Colors.white,
          avatarIcon: Icons.directions_walk,
          titleColor: const Color(0xFF111827),
          titleStrike: false,
          subtitleIcon: Icons.timelapse,
          subtitleColor: const Color(0xFF0E5A3B),
          chevronColor: const Color(0xFF0E5A3B),
          subtitle: (t) => t.isEmpty ? 'In progress' : 'In progress · $t',
        );
      case 'COMPLETED':
        return _ThemeFor._(
          background: const Color(0xFFD1FADF),
          borderColor: null,
          avatarBackground: Colors.white,
          avatarFg: const Color(0xFF0E5A3B),
          avatarIcon: Icons.check,
          titleColor: const Color(0xFF6B7280),
          titleStrike: true,
          subtitleIcon: Icons.check_circle,
          subtitleColor: const Color(0xFF0E5A3B),
          chevronColor: const Color(0xFF6B7280),
          subtitle: (t) => 'Completed',
        );
      case 'CANCELLED':
        return _ThemeFor._(
          background: const Color(0xFFFEE2E2),
          borderColor: null,
          avatarBackground: Colors.white,
          avatarFg: const Color(0xFFB91C1C),
          avatarIcon: Icons.close,
          titleColor: const Color(0xFF6B7280),
          titleStrike: true,
          subtitleIcon: Icons.cancel_outlined,
          subtitleColor: const Color(0xFFB91C1C),
          chevronColor: const Color(0xFF6B7280),
          subtitle: (t) => 'Cancelled',
        );
      default: // PENDING
        return _ThemeFor._(
          background: Colors.white,
          borderColor: const Color(0xFFD1FADF),
          avatarBackground: const Color(0xFFD1FADF),
          avatarFg: const Color(0xFF0E5A3B),
          avatarIcon: null,
          titleColor: const Color(0xFF111827),
          titleStrike: false,
          subtitleIcon: Icons.schedule,
          subtitleColor: const Color(0xFF6B7280),
          chevronColor: const Color(0xFF0E5A3B),
          subtitle: (t) => t.isEmpty ? 'Pending' : 'Due $t',
        );
    }
  }

  _ThemeFor._({
    required this.background,
    required this.borderColor,
    required this.avatarBackground,
    required this.avatarFg,
    required this.avatarIcon,
    required this.titleColor,
    required this.titleStrike,
    required this.subtitleIcon,
    required this.subtitleColor,
    required this.chevronColor,
    required this.subtitle,
  });
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available_outlined, color: Color(0xFF6B7280)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tasks scheduled for today',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
