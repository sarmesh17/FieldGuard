import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/tasks/data/dto/create_task_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_state.dart';
import 'package:fieldguard/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:fieldguard/widgets/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// The kind of bucket a tab shows. Each maps to a fixed slice of the
/// `GET /api/v1/tasks` query — see [_TaskTabViewState._applyFilters].
///
/// ADMIN sees [managerTasks] + [employeeTasks] (split by assignee role).
/// MANAGER sees [myTasks] + [teamTasks] (`view=my` / `view=team`).
/// EMPLOYEE sees only [myTasks].
enum _TaskTab { managerTasks, employeeTasks, myTasks, teamTasks }

List<_TaskTab> _tabsForRole(String role) => switch (role) {
  'ADMIN' => const [_TaskTab.managerTasks, _TaskTab.employeeTasks],
  'MANAGER' => const [_TaskTab.myTasks, _TaskTab.teamTasks],
  _ => const [_TaskTab.myTasks],
};

String _tabLabel(_TaskTab tab) => switch (tab) {
  _TaskTab.managerTasks => 'Manager Tasks',
  _TaskTab.employeeTasks => 'Employee Tasks',
  _TaskTab.myTasks => 'My Tasks',
  _TaskTab.teamTasks => 'Team Tasks',
};

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;

  String _role = 'EMPLOYEE';
  int _userId = 0;
  List<_TaskTab> _tabs = const [_TaskTab.myTasks];

  // One key per tab so the parent can ask the active tab to reload its own
  // (filtered) query on tab switch — the tabs share a single notifier, so
  // without this a switched-to tab would show the previous tab's data.
  List<GlobalKey<_TaskTabViewState>> _tabKeys = const [];

  @override
  void initState() {
    super.initState();

    final loginState = ref.read(loginNotifierProvider);
    if (loginState is LoginSuccess) {
      _role = loginState.response.user.role.toUpperCase();
      _userId = loginState.response.user.id;
    }

    _tabs = _tabsForRole(_role);
    _tabKeys = List.generate(
      _tabs.length,
      (_) => GlobalKey<_TaskTabViewState>(),
    );
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(_onTabChanged);

    // First-page load for the initial tab.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadActiveTab());
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final controller = _tabController!;
    if (controller.indexIsChanging) return;
    if (_currentTabIndex == controller.index) return;
    setState(() => _currentTabIndex = controller.index);
    _reloadActiveTab();
  }

  void _reloadActiveTab() {
    _tabKeys[_currentTabIndex].currentState?.reload();
  }

  void _openCreateTask() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
    if (created == true) _reloadActiveTab();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    final tasksState = ref.watch(tasksNotifierProvider);
    final taskCount = tasksState is TasksSuccess
        ? tasksState.pagination.total
        : null;

    if (loginState is! LoginSuccess || _tabController == null) {
      return const Scaffold(
        backgroundColor: AppColors.white2,
        body: SkeletonList(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white2,
      floatingActionButton: _CreateFAB(onPressed: _openCreateTask),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _TasksAppBar(
            taskCount: taskCount,
            onBack: () => Navigator.pop(context),
            tabController: _tabController!,
            tabLabels: [for (final t in _tabs) _tabLabel(t)],
          ),
        ],
        body: TabBarView(
          controller: _tabController!,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _TaskTabView(
                key: _tabKeys[i],
                tab: _tabs[i],
                role: _role,
                userId: _userId,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Task Tab View ────────────────────────────────────────────────────────────

/// One tab's content: filter bars + the paginated list. The bucket is fixed by
/// [tab]; the user can narrow it with the filter bars. [reload] re-runs the
/// first-page fetch with the current filters (used on tab switch / refresh).
class _TaskTabView extends ConsumerStatefulWidget {
  final _TaskTab tab;
  final String role;
  final int userId;

  const _TaskTabView({
    super.key,
    required this.tab,
    required this.role,
    required this.userId,
  });

  @override
  ConsumerState<_TaskTabView> createState() => _TaskTabViewState();
}

class _TaskTabViewState extends ConsumerState<_TaskTabView> {
  String? _selectedStatus;
  String? _selectedPriority;

  // ADMIN "Created by" picker (manager / employee tabs).
  List<ManagerItem> _managers = [];
  ManagerItem? _selectedCreator;
  bool _loadingManagers = false;

  // MANAGER "Team Tasks" extra filters.
  bool _onlyMine = false; // Created by me.
  String? _selectedAssigneeRole; // MANAGER / EMPLOYEE.

  static const _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH'];

  bool get _isAdminTab =>
      widget.tab == _TaskTab.managerTasks ||
      widget.tab == _TaskTab.employeeTasks;

  @override
  void initState() {
    super.initState();
    if (_isAdminTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchManagers());
    }
  }

  Future<void> _fetchManagers() async {
    setState(() => _loadingManagers = true);
    try {
      final dio = DioClient.createDio();
      final response = await dio.get(ApiConstant.getManagersEndpoint);
      final result = ManagersListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (mounted) setState(() => _managers = result.managers);
    } catch (_) {
      // Picker just stays empty ("All" still works) — non-fatal.
    } finally {
      if (mounted) setState(() => _loadingManagers = false);
    }
  }

  /// Re-runs the first-page fetch for this tab with its current filters.
  void reload() => _applyFilters();

  void _applyFilters() {
    final notifier = ref.read(tasksNotifierProvider.notifier);
    final selectedManagerId = _selectedCreator != null
        ? int.tryParse(_selectedCreator!.id)
        : null;

    switch (widget.tab) {
      case _TaskTab.managerTasks:
        // "Assigned to" filter — userId narrows to a specific manager-assignee.
        notifier.loadTasks(
          assigneeRole: 'MANAGER',
          userId: selectedManagerId,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
      case _TaskTab.employeeTasks:
        // "Created by" filter — createdBy narrows to tasks a manager delegated.
        notifier.loadTasks(
          assigneeRole: 'EMPLOYEE',
          createdBy: selectedManagerId,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
      case _TaskTab.myTasks:
        notifier.loadTasks(
          view: 'my',
          status: _selectedStatus,
          priority: _selectedPriority,
        );
      case _TaskTab.teamTasks:
        notifier.loadTasks(
          view: 'team',
          createdBy: _onlyMine ? widget.userId : null,
          assigneeRole: _selectedAssigneeRole,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
    }
  }

  Future<void> _refresh() async => _applyFilters();

  ({String title, String message}) get _emptyText => switch (widget.tab) {
    _TaskTab.managerTasks => (
      title: 'No manager tasks',
      message: 'No tasks have been assigned to managers yet.',
    ),
    _TaskTab.employeeTasks => (
      title: 'No employee tasks',
      message: 'No tasks have been assigned to employees yet.',
    ),
    _TaskTab.myTasks => (
      title: 'No tasks assigned',
      message: 'You have no tasks assigned to you.',
    ),
    _TaskTab.teamTasks => (
      title: 'No team tasks',
      message: 'No tasks for your team yet.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksNotifierProvider);
    final empty = _emptyText;

    return Column(
      children: [
        if (_isAdminTab)
          _AdminManagerPickerBar(
            managers: _managers,
            selected: _selectedCreator,
            loading: _loadingManagers,
            // Manager Tasks: filter by assignee ("Assigned to Ravi").
            // Employee Tasks: filter by creator ("Created by Ravi").
            filterLabel: widget.tab == _TaskTab.managerTasks
                ? 'Assigned to'
                : 'Created by',
            onChanged: (m) {
              setState(() => _selectedCreator = m);
              _applyFilters();
            },
          ),
        if (widget.tab == _TaskTab.teamTasks)
          _TeamFilterBar(
            onlyMine: _onlyMine,
            assigneeRole: _selectedAssigneeRole,
            onOnlyMineChanged: (v) {
              setState(() => _onlyMine = v);
              _applyFilters();
            },
            onAssigneeRoleChanged: (v) {
              setState(() => _selectedAssigneeRole = v);
              _applyFilters();
            },
          ),
        _SimpleFilterBar(
          selectedStatus: _selectedStatus,
          selectedPriority: _selectedPriority,
          statuses: _statuses,
          priorities: _priorities,
          onStatusChanged: (v) {
            setState(() => _selectedStatus = v);
            _applyFilters();
          },
          onPriorityChanged: (v) {
            setState(() => _selectedPriority = v);
            _applyFilters();
          },
        ),
        Expanded(
          child: switch (tasksState) {
            TasksInitial() || TasksLoading() => const _LoadingView(),
            TasksFailure(:final message) => _ErrorView(
              message: message,
              onRetry: _applyFilters,
            ),
            final TasksSuccess s => _PaginatedTaskList(
              state: s,
              onRefresh: _refresh,
              onLoadMore: () =>
                  ref.read(tasksNotifierProvider.notifier).loadMore(),
              emptyTitle: empty.title,
              emptyMessage: empty.message,
            ),
          },
        ),
      ],
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _TasksAppBar extends StatelessWidget {
  final int? taskCount;
  final VoidCallback onBack;
  final TabController tabController;
  final List<String> tabLabels;

  const _TasksAppBar({
    required this.taskCount,
    required this.onBack,
    required this.tabController,
    required this.tabLabels,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.green,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.green, AppColors.green],
                  ),
                ),
              ),
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Task Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (taskCount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '$taskCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TabBar(
                  controller: tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: [for (final label in tabLabels) Tab(text: label)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Created-by Picker Bar (ADMIN) ────────────────────────────────────────────

/// Admin manager picker bar — reused on both admin tabs but with different
/// semantics:
/// - Manager Tasks: "Assigned to" → the manager is the task's assignee.
/// - Employee Tasks: "Created by" → the manager is the task's creator.
class _AdminManagerPickerBar extends StatelessWidget {
  final List<ManagerItem> managers;
  final ManagerItem? selected;
  final bool loading;

  /// Label shown before the chips ("Assigned to:" or "Created by:").
  final String filterLabel;
  final ValueChanged<ManagerItem?> onChanged;

  const _AdminManagerPickerBar({
    required this.managers,
    required this.selected,
    required this.loading,
    required this.filterLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.white4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: loading
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.green,
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_pin_circle_outlined,
                    size: 15,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$filterLabel:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'All',
                    selected: selected == null,
                    color: AppColors.green,
                    icon: null,
                    onTap: () => onChanged(null),
                  ),
                  ...managers.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: m.fullName,
                        selected: selected?.id == m.id,
                        color: AppColors.green,
                        icon: null,
                        onTap: () => onChanged(selected?.id == m.id ? null : m),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Team Filter Bar (MANAGER → Team Tasks) ───────────────────────────────────

/// Extra filters for a manager's Team Tasks: "Created by me" toggle and an
/// assignee-role filter (so manager→manager delegations can be isolated).
class _TeamFilterBar extends StatelessWidget {
  final bool onlyMine;
  final String? assigneeRole;
  final ValueChanged<bool> onOnlyMineChanged;
  final ValueChanged<String?> onAssigneeRoleChanged;

  const _TeamFilterBar({
    required this.onlyMine,
    required this.assigneeRole,
    required this.onOnlyMineChanged,
    required this.onAssigneeRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.white4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipRow(
            icon: Icons.person_pin_circle_outlined,
            label: 'Created by',
            options: const ['MINE'],
            selected: onlyMine ? 'MINE' : null,
            colorOf: (_) => AppColors.green,
            labelOf: (_) => 'Me',
            iconOf: (_) => null,
            onChanged: (v) => onOnlyMineChanged(v == 'MINE'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ChipRow(
            icon: Icons.badge_outlined,
            label: 'Assignee',
            options: const ['MANAGER', 'EMPLOYEE'],
            selected: assigneeRole,
            colorOf: (_) => AppColors.green,
            labelOf: _capitalise,
            iconOf: (_) => null,
            onChanged: onAssigneeRoleChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Simple Filter Bar ────────────────────────────────────────────────────────

class _SimpleFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final String? selectedPriority;
  final List<String> statuses;
  final List<String> priorities;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;

  const _SimpleFilterBar({
    required this.selectedStatus,
    required this.selectedPriority,
    required this.statuses,
    required this.priorities,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipRow(
            icon: Icons.circle_outlined,
            label: 'Status',
            options: statuses,
            selected: selectedStatus,
            colorOf: _statusColor,
            labelOf: _statusLabel,
            iconOf: _statusIcon,
            onChanged: onStatusChanged,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ChipRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            options: priorities,
            selected: selectedPriority,
            colorOf: _priorityColor,
            labelOf: (v) => _capitalise(v),
            iconOf: (_) => null,
            onChanged: onPriorityChanged,
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> options;
  final String? selected;
  final Color Function(String) colorOf;
  final String Function(String) labelOf;
  final IconData? Function(String) iconOf;
  final ValueChanged<String?> onChanged;

  const _ChipRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.colorOf,
    required this.labelOf,
    required this.iconOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.grey),
            const SizedBox(width: 6),
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'All',
              selected: selected == null,
              color: AppColors.green,
              icon: null,
              onTap: () => onChanged(null),
            ),
            ...options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: labelOf(opt),
                  selected: selected == opt,
                  color: colorOf(opt),
                  icon: iconOf(opt),
                  onTap: () => onChanged(selected == opt ? null : opt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white2,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: selected ? Colors.white : AppColors.grey,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Paginated Task List ──────────────────────────────────────────────────────

/// Renders the task summaries with pull-to-refresh and infinite scroll.
///
/// The list endpoint is paged — we never load everything at once. When the
/// user scrolls near the bottom we ask the notifier for the next page (it
/// guards against duplicate / out-of-range fetches itself).
class _PaginatedTaskList extends StatefulWidget {
  final TasksSuccess state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final String emptyTitle;
  final String emptyMessage;

  const _PaginatedTaskList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  State<_PaginatedTaskList> createState() => _PaginatedTaskListState();
}

class _PaginatedTaskListState extends State<_PaginatedTaskList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.state.tasks;
    if (tasks.isEmpty) {
      return _EmptyView(title: widget.emptyTitle, message: widget.emptyMessage);
    }

    final showFooter = widget.state.isLoadingMore || widget.state.hasMore;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.green,
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        itemCount: tasks.length + (showFooter ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= tasks.length) return const _LoadMoreFooter();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TaskCard(task: tasks[i]),
          );
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.green,
          ),
        ),
      ),
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskSummary task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);
    final initial = task.assignee.fullName.isNotEmpty
        ? task.assignee.fullName[0].toUpperCase()
        : '?';
    final subtitle = (task.assignee.employeeCode?.isNotEmpty ?? false)
        ? task.assignee.employeeCode!
        : (task.manager != null ? 'Mgr: ${task.manager!.fullName}' : '');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        priorityColor,
                        priorityColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _PriorityDot(color: priorityColor),
                            const SizedBox(width: 6),
                            Text(
                              _capitalise(task.priority),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            _StatusBadge(
                              label: _statusLabel(task.status),
                              color: statusColor,
                              icon: _statusIcon(task.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _ShopRow(shop: task.shop),
                        if (task.creator != null) ...[
                          const SizedBox(height: 8),
                          _CreatorChip(creator: task.creator!),
                        ],
                        const SizedBox(height: 12),
                        Container(height: 1, color: AppColors.white4),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Avatar(initial: initial, color: priorityColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.assignee.fullName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(task.dueDate),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows who assigned the task — `By Admin` or `By Mgr: <name>` — so the
/// creator is visible on the card and never hidden behind a tab.
class _CreatorChip extends StatelessWidget {
  final TaskPerson creator;

  const _CreatorChip({required this.creator});

  @override
  Widget build(BuildContext context) {
    final isAdmin = (creator.role ?? '').toUpperCase() == 'ADMIN';
    final label = isAdmin ? 'By Admin' : 'By Mgr: ${creator.fullName}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white4,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield_outlined : Icons.supervisor_account_outlined,
            size: 12,
            color: AppColors.grey,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  final TaskShop? shop;

  const _ShopRow({required this.shop});

  @override
  Widget build(BuildContext context) {
    final hasImage = shop?.shopImage != null && shop!.shopImage!.isNotEmpty;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white4,
            borderRadius: BorderRadius.circular(6),
          ),
          child: hasImage
              ? Image.network(
                  shop!.shopImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.store_rounded,
                    size: 14,
                    color: AppColors.grey8,
                  ),
                )
              : const Icon(
                  Icons.store_rounded,
                  size: 14,
                  color: AppColors.grey8,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            shop?.name.isNotEmpty == true
                ? shop!.name
                : 'Legacy task — no shop linked',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: shop == null
                  ? AppColors.grey8
                  : AppColors.grey10,
              fontStyle: shop == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final Color color;

  const _PriorityDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final Color color;

  const _Avatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _CreateFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.green, AppColors.green],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'New Task',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading / Empty / Error ──────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SkeletonList();
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyView({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.green6, AppColors.green6],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 44,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey8,
                height: 1.5,
              ),
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
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: AppColors.red5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.grey8),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
  'COMPLETED' => AppColors.green,
  'CANCELLED' => AppColors.red5,
  _ => AppColors.grey,
};

IconData? _statusIcon(String status) => switch (status.toUpperCase()) {
  'PENDING' => Icons.hourglass_top_rounded,
  'IN_PROGRESS' => Icons.autorenew_rounded,
  'COMPLETED' => Icons.check_circle_outline_rounded,
  'CANCELLED' => Icons.cancel_outlined,
  _ => null,
};

String _statusLabel(String status) => switch (status.toUpperCase()) {
  'IN_PROGRESS' => 'In Progress',
  _ => _capitalise(status),
};

Color _priorityColor(String priority) => switch (priority.toUpperCase()) {
  'HIGH' => AppColors.red4,
  'MEDIUM' => AppColors.orange2,
  'LOW' => AppColors.blue3,
  _ => AppColors.grey,
};

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}
