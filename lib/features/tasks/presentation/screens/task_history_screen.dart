import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/presentation/providers/task_history_state.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

const _kBrand = AppColors.green2;
const _kInk = AppColors.ink2;
const _kMuted = AppColors.grey8;
const _kBg = AppColors.white3;

/// Full-screen task audit feed (`GET /api/v1/tasks/history`).
///
/// Opened with no [taskId] from Task Management → the whole role-scoped
/// feed. Pass a [taskId] to scope it to one task. The backend already
/// limits what each role can see; we just render it.
class TaskHistoryScreen extends ConsumerStatefulWidget {
  final int? taskId;
  final String? taskTitle;

  const TaskHistoryScreen({super.key, this.taskId, this.taskTitle});

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(taskHistoryNotifierProvider.notifier)
          .load(taskId: widget.taskId);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(taskHistoryNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() =>
      ref.read(taskHistoryNotifierProvider.notifier).load(taskId: widget.taskId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskHistoryNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBrand,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              widget.taskTitle ?? 'Audit trail · newest first',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: switch (state) {
        TaskHistoryInitial() || TaskHistoryLoading() => const SkeletonList(),
        TaskHistoryFailure(:final message) => _ErrorView(
            message: message,
            onRetry: _refresh,
          ),
        final TaskHistorySuccess s => s.entries.isEmpty
            ? const _EmptyView()
            : RefreshIndicator(
                onRefresh: _refresh,
                color: _kBrand,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount:
                      s.entries.length + (s.isLoadingMore || s.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= s.entries.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: _kBrand,
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HistoryCard(
                        entry: s.entries[i],
                        showTask: widget.taskId == null,
                      ),
                    );
                  },
                ),
              ),
      },
    );
  }
}

// ─── History entry card ───────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final TaskHistoryEntry entry;

  /// When viewing one task's history the task line is redundant.
  final bool showTask;

  const _HistoryCard({required this.entry, required this.showTask});

  @override
  Widget build(BuildContext context) {
    final changes = _diff(entry.oldValues, entry.newValues);
    final reason = entry.changeReason;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ActionBadge(action: entry.action),
                const Spacer(),
                Text(
                  _formatDateTime(entry.createdAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
            if (showTask) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 15, color: _kMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.task.title ?? 'Task #${entry.task.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.task.status != null) ...[
                    const SizedBox(width: 8),
                    _StatusPill(status: entry.task.status!),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            _PerformerLine(performer: entry.performer),
            if (reason != null) ...[
              const SizedBox(height: 12),
              _ReasonCallout(reason: reason),
            ],
            if (changes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...changes.map((c) => _ChangeRow(change: c)),
            ],
            if (entry.ipAddress != null && entry.ipAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.public_rounded, size: 12, color: _kMuted),
                  const SizedBox(width: 5),
                  Text(
                    'from ${entry.ipAddress}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PerformerLine extends StatelessWidget {
  final TaskHistoryPerformer? performer;

  const _PerformerLine({required this.performer});

  @override
  Widget build(BuildContext context) {
    final name = performer?.fullName ?? 'System';
    final role = performer?.role;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kBrand, AppColors.green7],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.5,
                color: _kInk,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: name),
                if (role != null && role.isNotEmpty)
                  TextSpan(
                    text: '  ·  ${_capitalise(role)}',
                    style: const TextStyle(
                      color: _kMuted,
                      fontWeight: FontWeight.w500,
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

class _ReasonCallout extends StatelessWidget {
  final String reason;

  const _ReasonCallout({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kBrand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBrand.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 14, color: _kBrand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 12.5,
                color: _kInk,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final _FieldChange change;

  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.east_rounded, size: 12, color: _kMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, height: 1.4),
                children: [
                  TextSpan(
                    text: '${_prettyKey(change.field)}: ',
                    style: const TextStyle(
                      color: _kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (change.oldValue != null) ...[
                    TextSpan(
                      text: change.oldValue,
                      style: const TextStyle(
                        color: AppColors.red14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const TextSpan(
                      text: '  →  ',
                      style: TextStyle(color: _kMuted),
                    ),
                  ],
                  TextSpan(
                    text: change.newValue,
                    style: const TextStyle(
                      color: _kInk,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ActionBadge extends StatelessWidget {
  final String action;

  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBrand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _prettyAction(action),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _kBrand,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toUpperCase()) {
      'PENDING' => AppColors.orange2,
      'IN_PROGRESS' => AppColors.blue3,
      'COMPLETED' => _kBrand,
      'CANCELLED' => AppColors.red5,
      _ => _kMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _capitalise(status.replaceAll('_', ' ')),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  size: 42, color: _kBrand),
            ),
            const SizedBox(height: 22),
            const Text(
              'No history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Task changes will show up here as they happen.',
              style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              'Could not load history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: _kMuted),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diff + formatting helpers ────────────────────────────────────────────────

class _FieldChange {
  final String field;
  final String? oldValue;
  final String newValue;

  const _FieldChange(this.field, this.oldValue, this.newValue);
}

/// Builds a human diff from the audit blobs. `changeReason` is shown in its
/// own callout, so it's excluded here. Falls back to whichever side has
/// data when only one is present.
List<_FieldChange> _diff(
  Map<String, dynamic>? oldValues,
  Map<String, dynamic>? newValues,
) {
  final result = <_FieldChange>[];
  final keys = <String>{
    ...?newValues?.keys,
    ...?oldValues?.keys,
  }..remove('changeReason');

  for (final k in keys) {
    final oldV = oldValues == null ? null : _stringify(oldValues[k]);
    final newV = newValues == null ? null : _stringify(newValues[k]);
    if (newV == null && oldV == null) continue;
    if (oldV == newV) continue; // unchanged — don't clutter
    result.add(_FieldChange(k, oldV, newV ?? '—'));
  }
  return result;
}

String? _stringify(Object? v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? '—' : v;
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is num) return v.toString();
  if (v is List) return v.join(', ');
  return v.toString();
}

String _prettyAction(String a) =>
    a.isEmpty ? 'Change' : a.split('_').map(_capitalise).join(' ');

String _prettyKey(String k) {
  // snake_case or camelCase → "Title Case"
  final spaced = k
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}');
  return spaced.split(' ').map(_capitalise).join(' ');
}

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

String _formatDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m $ap';
  } catch (_) {
    return iso;
  }
}
