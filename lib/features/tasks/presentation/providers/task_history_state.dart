import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart'
    show Pagination;

sealed class TaskHistoryState {
  const TaskHistoryState();
}

class TaskHistoryInitial extends TaskHistoryState {
  const TaskHistoryInitial();
}

class TaskHistoryLoading extends TaskHistoryState {
  const TaskHistoryLoading();
}

class TaskHistorySuccess extends TaskHistoryState {
  const TaskHistorySuccess(
    this.entries,
    this.pagination, {
    this.isLoadingMore = false,
  });

  final List<TaskHistoryEntry> entries;
  final Pagination pagination;
  final bool isLoadingMore;

  bool get hasMore => pagination.hasMore;

  TaskHistorySuccess copyWith({
    List<TaskHistoryEntry>? entries,
    Pagination? pagination,
    bool? isLoadingMore,
  }) {
    return TaskHistorySuccess(
      entries ?? this.entries,
      pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TaskHistoryFailure extends TaskHistoryState {
  const TaskHistoryFailure(this.message);
  final String message;
}
