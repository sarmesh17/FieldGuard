import 'dart:async';
import 'dart:io';

import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/live_tracking/data/models/live_location.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
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
import 'package:fieldguard/core/theme/app_colors.dart';

part 'task_detail_status_widgets.dart';
part 'task_detail_content_widgets.dart';
part 'task_detail_action_widgets.dart';

const _kBrand = AppColors.green;
const _kBrandLight = AppColors.green;
const _kInk = AppColors.ink2;
const _kMuted = AppColors.grey2;
const _kBg = AppColors.white;

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
  final _socket = LiveTrackingSocket.instance;

  // Local, mutable checklist state — patched by the assignee's PATCH response
  // and by live `task:item_updated` socket events (viewer side), so the list
  // + progress badge update without a full refetch.
  late List<TaskItem> _items;
  late int _progressTotal;
  late int _progressDone;
  int? _togglingItemId; // item being PATCHed (shows a spinner, blocks re-tap)
  StreamSubscription<TaskItemUpdatedEvent>? _itemSub;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _items = List.of(widget.task.items);
    _progressTotal = widget.task.itemsProgress.total;
    _progressDone = widget.task.itemsProgress.done;

    // Join the task's room and listen for live checklist changes (a manager/
    // admin watches the assignee tick items in real time). Harmless for the
    // assignee — their own ticks echo back and match the PATCH result.
    _socket.emitTaskWatch(widget.task.id);
    _itemSub = _socket.onTaskItemUpdated.listen(_onItemUpdated);
  }

  @override
  void dispose() {
    _itemSub?.cancel();
    _socket.emitTaskUnwatch(widget.task.id);
    _entrance.dispose();
    super.dispose();
  }

  /// Live checklist update from another device (the assignee ticking an item).
  void _onItemUpdated(TaskItemUpdatedEvent e) {
    if (!mounted || e.taskId != widget.task.id.toString()) return;
    final idx = _items.indexWhere((i) => i.id == e.itemId);
    setState(() {
      if (idx >= 0) {
        _items[idx] = _items[idx]
            .copyWith(done: e.done, doneAt: e.doneAt, doneBy: e.doneBy);
      }
      _progressTotal = e.progressTotal;
      _progressDone = e.progressDone;
    });
  }

  /// True when the logged-in user is this task's assignee (only they may tick).
  bool get _isAssignee {
    final login = ref.read(loginNotifierProvider);
    return login is LoginSuccess &&
        widget.task.assignedTo != null &&
        login.response.user.id == widget.task.assignedTo;
  }

  /// Assignee taps a checkbox → PATCH the item, then reconcile from the server
  /// response (items + progress). A failure (e.g. task already COMPLETED)
  /// surfaces a snackbar and leaves the box unchanged.
  Future<void> _toggleItem(TaskItem item) async {
    final id = item.id;
    if (id == null || _togglingItemId != null) return;
    setState(() => _togglingItemId = id);
    try {
      final res = await TaskDataSourceImpl(DioClient.createDio())
          .toggleTaskItem(widget.task.id, id, done: !item.done);
      if (!mounted) return;
      setState(() {
        _items = List.of(res.task.items);
        _progressTotal = res.task.itemsProgress.total;
        _progressDone = res.task.itemsProgress.done;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update the item. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _togglingItemId = null);
    }
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

  /// Opens the collection form for this task's shop. We pass both the shop
  /// (from the linked shop) and the task id, so the API can also notify the
  /// task's responsible manager.
  void _collectPayment(TaskData task) {
    final shop = task.shop;
    if (shop == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectPaymentScreen(
          shopId: shop.id,
          shopName: shop.name,
          taskId: task.id,
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
                fontSize: 14, height: 1.55, color: AppColors.blue2),
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (_items.isNotEmpty) ...[
        _LabeledCard(
          icon: Icons.checklist_rounded,
          title: 'Checklist',
          trailing: _ProgressPill(done: _progressDone, total: _progressTotal),
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 18, color: AppColors.white),
                _ChecklistItem(
                  text: _items[i].text,
                  index: i,
                  done: _items[i].done,
                  busy: _togglingItemId != null &&
                      _togglingItemId == _items[i].id,
                  // Only the assignee may tick, and only while the task is
                  // still open (PENDING / IN_PROGRESS). Others see it read-only.
                  onToggle: (_isAssignee &&
                          _items[i].id != null &&
                          _canUpdate(task.status))
                      ? () => _toggleItem(_items[i])
                      : null,
                ),
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
            const Divider(height: 22, color: AppColors.white),
            _PersonRow(
              icon: Icons.edit_note_rounded,
              role: 'Created by',
              name: task.creator.fullName,
              subtitle: null,
            ),
            if (task.manager != null) ...[
              const Divider(height: 22, color: AppColors.white),
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
                fontSize: 14, height: 1.55, color: AppColors.blue2),
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

