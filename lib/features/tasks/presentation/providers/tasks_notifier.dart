import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/domain/usecase/get_tasks_usecase.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class _TasksQuery {
  final String? search;
  final String? status;
  final String? priority;
  final int? userId;
  final int? managerId;
  final bool? hasManager;
  final String? assigneeRole;
  final int? createdBy;
  final String? view;

  const _TasksQuery({
    this.search,
    this.status,
    this.priority,
    this.userId,
    this.managerId,
    this.hasManager,
    this.assigneeRole,
    this.createdBy,
    this.view,
  });
}

class TasksNotifier extends StateNotifier<TasksState> {
  final GetTasksUsecase _usecase;

  TasksNotifier(this._usecase) : super(const TasksInitial());

  static const _pageSize = 20;

  _TasksQuery _query = const _TasksQuery();

  /// Loads the first page, replacing any existing list. Remembers the
  /// filters so [loadMore] can fetch subsequent pages with the same query.
  Future<void> loadTasks({
    String? search,
    String? status,
    String? priority,
    int? userId,
    int? managerId,
    bool? hasManager,
    String? assigneeRole,
    int? createdBy,
    String? view,
  }) async {
    _query = _TasksQuery(
      search: search,
      status: status,
      priority: priority,
      userId: userId,
      managerId: managerId,
      hasManager: hasManager,
      assigneeRole: assigneeRole,
      createdBy: createdBy,
      view: view,
    );

    state = const TasksLoading();

    final result = await _usecase(
      page: 1,
      limit: _pageSize,
      search: _query.search,
      status: _query.status,
      priority: _query.priority,
      userId: _query.userId,
      managerId: _query.managerId,
      hasManager: _query.hasManager,
      assigneeRole: _query.assigneeRole,
      createdBy: _query.createdBy,
      view: _query.view,
    );

    state = switch (result) {
      Success(:final data) => TasksSuccess(data.tasks, data.pagination),
      Failure(:final exception) => TasksFailure(
          exception is AppException ? exception.message : 'Something went wrong',
        ),
    };
  }

  /// Fetches the next page and appends it to the current list.
  Future<void> loadMore() async {
    final current = state;
    if (current is! TasksSuccess) return;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true);

    final result = await _usecase(
      page: current.pagination.page + 1,
      limit: _pageSize,
      search: _query.search,
      status: _query.status,
      priority: _query.priority,
      userId: _query.userId,
      managerId: _query.managerId,
      hasManager: _query.hasManager,
      assigneeRole: _query.assigneeRole,
      createdBy: _query.createdBy,
      view: _query.view,
    );

    switch (result) {
      case Success(:final data):
        state = TasksSuccess(
          [...current.tasks, ...data.tasks],
          data.pagination,
        );
      case Failure():
        // Keep what we have; just stop the spinner.
        state = current.copyWith(isLoadingMore: false);
    }
  }
}
