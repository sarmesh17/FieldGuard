import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/domain/usecase/get_task_history_usecase.dart';
import 'package:fieldguard/features/tasks/presentation/providers/task_history_state.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Drives the task audit feed: first page on [load], then [loadMore] for
/// infinite scroll. The active filters are remembered so paging keeps the
/// same query. Visibility is enforced server-side by the caller's role.
class TaskHistoryNotifier extends StateNotifier<TaskHistoryState> {
  final GetTaskHistoryUsecase _usecase;

  TaskHistoryNotifier(this._usecase) : super(const TaskHistoryInitial());

  static const _pageSize = 20;

  int? _taskId;
  int? _performedBy;
  String? _action;

  Future<void> load({
    int? taskId,
    int? performedBy,
    String? action,
  }) async {
    _taskId = taskId;
    _performedBy = performedBy;
    _action = action;

    state = const TaskHistoryLoading();

    final result = await _usecase(
      taskId: _taskId,
      performedBy: _performedBy,
      action: _action,
      page: 1,
      limit: _pageSize,
    );

    state = switch (result) {
      Success(:final data) =>
        TaskHistorySuccess(data.history, data.pagination),
      Failure(:final exception) => TaskHistoryFailure(
          exception is AppException ? exception.message : 'Something went wrong',
        ),
    };
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! TaskHistorySuccess) return;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true);

    final result = await _usecase(
      taskId: _taskId,
      performedBy: _performedBy,
      action: _action,
      page: current.pagination.page + 1,
      limit: _pageSize,
    );

    switch (result) {
      case Success(:final data):
        state = TaskHistorySuccess(
          [...current.entries, ...data.history],
          data.pagination,
        );
      case Failure():
        // Keep what we have; just stop the footer spinner.
        state = current.copyWith(isLoadingMore: false);
    }
  }
}
