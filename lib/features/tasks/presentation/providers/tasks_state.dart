import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';

sealed class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksSuccess extends TasksState {
  const TasksSuccess(
    this.tasks,
    this.pagination, {
    this.isLoadingMore = false,
  });

  final List<TaskSummary> tasks;
  final Pagination pagination;
  final bool isLoadingMore;

  bool get hasMore => pagination.hasMore;

  TasksSuccess copyWith({
    List<TaskSummary>? tasks,
    Pagination? pagination,
    bool? isLoadingMore,
  }) {
    return TasksSuccess(
      tasks ?? this.tasks,
      pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TasksFailure extends TasksState {
  const TasksFailure(this.message);
  final String message;
}
