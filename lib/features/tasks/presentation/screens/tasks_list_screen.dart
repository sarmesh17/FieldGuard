import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_state.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_state.dart';
import 'package:fieldguard/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasksForCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTasksForCurrentTab() {
    final loginState = ref.read(loginNotifierProvider);
    if (loginState is! LoginSuccess) return;

    final userId = loginState.response.user.id;
    final role = loginState.response.user.role.toUpperCase();

    if (_currentTabIndex == 0) {
      // EMPLOYEE: filter by assigned-to. MANAGER: filter by managerId. ADMIN: no filter (sees all).
      if (role == 'EMPLOYEE') {
        ref.read(tasksNotifierProvider.notifier).loadTasks(userId: userId);
      } else if (role == 'MANAGER') {
        ref.read(tasksNotifierProvider.notifier).loadTasks(managerId: userId);
      } else {
        ref.read(tasksNotifierProvider.notifier).loadTasks();
      }
    } else {
      // Team Tasks: MANAGER filters by own managerId. ADMIN sees only manager-assigned tasks.
      if (role == 'MANAGER') {
        ref.read(tasksNotifierProvider.notifier).loadTasks(managerId: userId);
      } else {
        ref.read(tasksNotifierProvider.notifier).loadTasks(hasManager: true);
      }
    }
  }

  void _openCreateTask() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
    if (created == true) _loadTasksForCurrentTab();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    final tasksState = ref.watch(tasksNotifierProvider);
    final taskCount =
        tasksState is TasksSuccess ? tasksState.pagination.total : null;

    return Scaffold(
      backgroundColor: const Color(0xffF2F4F7),
      floatingActionButton: _CreateFAB(onPressed: _openCreateTask),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _TasksAppBar(
            taskCount: taskCount,
            onBack: () => Navigator.pop(context),
            tabController: _tabController,
          ),
        ],
        body: loginState is! LoginSuccess
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _EmployeeTasksView(
                    userId: loginState.response.user.id,
                    role: loginState.response.user.role.toUpperCase(),
                    onTabChanged: _loadTasksForCurrentTab,
                  ),
                  _ManagerTasksView(
                    managerId: loginState.response.user.id,
                    role: loginState.response.user.role.toUpperCase(),
                    onTabChanged: _loadTasksForCurrentTab,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Employee Tasks View ──────────────────────────────────────────────────────

class _EmployeeTasksView extends ConsumerStatefulWidget {
  final int userId;
  final String role;
  final VoidCallback onTabChanged;

  const _EmployeeTasksView({
    required this.userId,
    required this.role,
    required this.onTabChanged,
  });

  @override
  ConsumerState<_EmployeeTasksView> createState() => _EmployeeTasksViewState();
}

class _EmployeeTasksViewState extends ConsumerState<_EmployeeTasksView> {
  String? _selectedStatus;
  String? _selectedPriority;

  static const _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    ref.read(tasksNotifierProvider.notifier).loadTasks(
          userId: widget.role == 'EMPLOYEE' ? widget.userId : null,
          managerId: widget.role == 'MANAGER' ? widget.userId : null,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
  }

  Future<void> _refresh() async {
    await ref.read(tasksNotifierProvider.notifier).loadTasks(
          userId: widget.role == 'EMPLOYEE' ? widget.userId : null,
          managerId: widget.role == 'MANAGER' ? widget.userId : null,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksNotifierProvider);

    return Column(
      children: [
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
                emptyTitle: 'No tasks assigned',
                emptyMessage: 'You have no tasks assigned to you.',
              ),
          },
        ),
      ],
    );
  }
}

// ─── Manager Tasks View ───────────────────────────────────────────────────────

class _ManagerTasksView extends ConsumerStatefulWidget {
  final int managerId;
  final String role;
  final VoidCallback onTabChanged;

  const _ManagerTasksView({
    required this.managerId,
    required this.role,
    required this.onTabChanged,
  });

  @override
  ConsumerState<_ManagerTasksView> createState() => _ManagerTasksViewState();
}

class _ManagerTasksViewState extends ConsumerState<_ManagerTasksView> {
  String? _selectedStatus;
  String? _selectedPriority;
  List<ManagerItem> _managers = [];
  ManagerItem? _selectedManager;
  bool _loadingManagers = false;

  static const _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.role == 'ADMIN') _fetchManagers();
      _applyFilters();
    });
  }

  Future<void> _fetchManagers() async {
    setState(() => _loadingManagers = true);
    try {
      final dio = DioClient.createDio();
      final response = await dio.get(ApiConstant.getManagersEndpoint);
      final result = ManagersListResponse.fromJson(response.data as Map<String, dynamic>);
      if (mounted) setState(() => _managers = result.managers);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingManagers = false);
    }
  }

  int? get _effectiveManagerId {
    if (widget.role == 'MANAGER') return widget.managerId;
    if (_selectedManager != null) return int.tryParse(_selectedManager!.id);
    return null;
  }

  // ADMIN with "All" selected → ask backend for tasks that have a manager.
  bool? get _hasManager =>
      (widget.role == 'ADMIN' && _selectedManager == null) ? true : null;

  void _applyFilters() {
    ref.read(tasksNotifierProvider.notifier).loadTasks(
          managerId: _effectiveManagerId,
          hasManager: _hasManager,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
  }

  Future<void> _refresh() async {
    await ref.read(tasksNotifierProvider.notifier).loadTasks(
          managerId: _effectiveManagerId,
          hasManager: _hasManager,
          status: _selectedStatus,
          priority: _selectedPriority,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksNotifierProvider);

    return Column(
      children: [
        if (widget.role == 'ADMIN') _ManagerPickerBar(
          managers: _managers,
          selected: _selectedManager,
          loading: _loadingManagers,
          onChanged: (m) {
            setState(() => _selectedManager = m);
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
                emptyTitle: 'No team tasks',
                emptyMessage: 'No tasks found for this manager.',
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

  const _TasksAppBar({
    required this.taskCount,
    required this.onBack,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xff005C33),
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
                    colors: [Color(0xff004D2B), Color(0xff00874C)],
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
                  tabs: const [
                    Tab(text: 'My Tasks'),
                    Tab(text: 'Team Tasks'),
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

// ─── Manager Picker Bar ───────────────────────────────────────────────────────

class _ManagerPickerBar extends StatelessWidget {
  final List<ManagerItem> managers;
  final ManagerItem? selected;
  final bool loading;
  final ValueChanged<ManagerItem?> onChanged;

  const _ManagerPickerBar({
    required this.managers,
    required this.selected,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffF0F2F5))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: loading
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff005C33),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 15, color: Color(0xff687184)),
                  const SizedBox(width: 6),
                  const Text(
                    'Manager:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff687184),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'All',
                    selected: selected == null,
                    color: const Color(0xff005C33),
                    icon: null,
                    onTap: () => onChanged(null),
                  ),
                  ...managers.map((m) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: m.fullName,
                          selected: selected?.id == m.id,
                          color: const Color(0xff005C33),
                          icon: null,
                          onTap: () => onChanged(selected?.id == m.id ? null : m),
                        ),
                      )),
                ],
              ),
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
            color: Color(0x0A000000),
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
            Icon(icon, size: 15, color: const Color(0xff687184)),
            const SizedBox(width: 6),
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xff687184),
              ),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'All',
              selected: selected == null,
              color: const Color(0xff005C33),
              icon: null,
              onTap: () => onChanged(null),
            ),
            ...options.map((opt) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: labelOf(opt),
                    selected: selected == opt,
                    color: colorOf(opt),
                    icon: iconOf(opt),
                    onTap: () => onChanged(selected == opt ? null : opt),
                  ),
                )),
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
          color: selected ? color : const Color(0xffF4F6F8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: selected ? Colors.white : const Color(0xff687184)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xff687184),
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
      color: const Color(0xff005C33),
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
            color: Color(0xff005C33),
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
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: task.id),
        ),
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
                          color: Color(0xff0D1B2A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: const Color(0xffF0F2F5),
                      ),
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
                                    color: Color(0xff0D1B2A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xff8A94A6),
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
                              color: const Color(0xffF4F6F8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: Color(0xff687184),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff687184),
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
            colors: [Color(0xff005C33), Color(0xff00874C)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff005C33).withValues(alpha: 0.45),
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
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xff005C33),
        strokeWidth: 2.5,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyView({
    required this.title,
    required this.message,
  });

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
                  colors: [Color(0xffE8F5EE), Color(0xffD0EDE0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff005C33).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 44,
                color: Color(0xff005C33),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xff0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff8A94A6),
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
                color: const Color(0xffFF3347).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: Color(0xffFF3347),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xff8A94A6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff005C33),
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
      'PENDING' => const Color(0xffF59E0B),
      'IN_PROGRESS' => const Color(0xff3B82F6),
      'COMPLETED' => const Color(0xff005C33),
      'CANCELLED' => const Color(0xffFF3347),
      _ => const Color(0xff687184),
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
      'HIGH' => const Color(0xffEF4444),
      'MEDIUM' => const Color(0xffF59E0B),
      'LOW' => const Color(0xff3B82F6),
      _ => const Color(0xff687184),
    };

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}
