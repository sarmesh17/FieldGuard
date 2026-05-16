import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/repository/tasks_repository_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/task_detail_response.dart';
import 'package:fieldguard/features/tasks/domain/repository/tasks_repository.dart';
import 'package:fieldguard/features/tasks/domain/usecase/get_task_detail_usecase.dart';
import 'package:fieldguard/features/tasks/domain/usecase/get_tasks_usecase.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_notifier.dart';
import 'package:fieldguard/features/tasks/presentation/providers/tasks_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final tasksDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final tasksDataSourceProvider = Provider<TaskDataSourceImpl>(
  (ref) => TaskDataSourceImpl(ref.watch(tasksDioProvider)),
);

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepositoryImpl(ref.watch(tasksDataSourceProvider)),
);

final getTasksUsecaseProvider = Provider<GetTasksUsecase>(
  (ref) => GetTasksUsecase(ref.watch(tasksRepositoryProvider)),
);

final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, TasksState>(
  (ref) => TasksNotifier(ref.watch(getTasksUsecaseProvider)),
);

final getTaskDetailUsecaseProvider = Provider<GetTaskDetailUsecase>(
  (ref) => GetTaskDetailUsecase(ref.watch(tasksRepositoryProvider)),
);

/// Fetches full task data for the detail screen, keyed by task id.
final taskDetailProvider =
    FutureProvider.family.autoDispose<TaskDetailResponse, int>((ref, id) async {
  final result = await ref.watch(getTaskDetailUsecaseProvider)(id);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };
});
