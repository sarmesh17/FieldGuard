import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/tasks/data/datasource/task_datasource_impl.dart';
import 'package:fieldguard/features/tasks/data/dto/task_history_response.dart';
import 'package:fieldguard/features/tasks/data/dto/tasks_list_response.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aggregated summary model for the dashboard
class DashboardSummary {
  final String fullName;
  final String? profileImage;
  final String role;

  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;

  final int onlineTeam;
  final int totalTeam;

  const DashboardSummary({
    required this.fullName,
    this.profileImage,
    this.role = '',
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.onlineTeam,
    required this.totalTeam,
  });

  int get offlineTeam => totalTeam - onlineTeam;
  int get totalTasks => pendingTasks + inProgressTasks + completedTasks;

  DashboardSummary copyWith({
    String? fullName,
    String? profileImage,
    String? role,
    int? pendingTasks,
    int? inProgressTasks,
    int? completedTasks,
    int? onlineTeam,
    int? totalTeam,
  }) {
    return DashboardSummary(
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      onlineTeam: onlineTeam ?? this.onlineTeam,
      totalTeam: totalTeam ?? this.totalTeam,
    );
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final me = json['me']?['user'] ?? {};

    final pending = json['pendingTasks']?['pagination']?['total'] ?? 0;
    final inProgress = json['inProgressTasks']?['pagination']?['total'] ?? 0;
    final completed = json['completedTasks']?['pagination']?['total'] ?? 0;

    final liveEmployees = json['liveEmployees']?['count'] ?? 0;

    return DashboardSummary(
      fullName: me['full_name'] ?? '',
      profileImage: me['profile_image'],
      role: me['role'] ?? '',
      pendingTasks: pending,
      inProgressTasks: inProgress,
      completedTasks: completed,
      onlineTeam: liveEmployees,
      totalTeam: liveEmployees, // Will be updated by the provider
    );
  }
}

/// Daily task progress from `GET /dashboard/today-tasks` — same bucket shape
/// as the summary, but scoped to tasks due TODAY. Drives the "Today" ring.
class DailyProgress {
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;

  const DailyProgress({
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
  });

  int get totalTasks => pendingTasks + inProgressTasks + completedTasks;
  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    int total(String key) => json[key]?['pagination']?['total'] ?? 0;
    return DailyProgress(
      pendingTasks: total('pendingTasks'),
      inProgressTasks: total('inProgressTasks'),
      completedTasks: total('completedTasks'),
    );
  }
}

// Private Dio for dashboard
final _dashboardDioProvider = Provider<Dio>((ref) => DioClient.createDio());

/// Single provider that fetches all dashboard data.
///
/// Task counts are read from `/dashboard/summary` (`*.pagination.total`).
/// NOTE: those totals are currently wrong on the backend — see
/// BACKEND_DASHBOARD_SUMMARY_FIX.md. Once the API returns the real COUNT(*)
/// for each bucket, the numbers here become correct with no client change.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) async {
  final dio = ref.watch(_dashboardDioProvider);

  // 1. Aggregated summary (profile + task buckets + live team).
  final response = await dio.get(ApiConstant.dashboardSummaryEndpoint);
  final data = response.data as Map<String, dynamic>;
  final summary = DashboardSummary.fromJson(data);

  // 2. Total employees — for the offline-team count (summary has no team total).
  final teamDs = TeamDataSourceImpl(dio);
  final allRes = await teamDs.getEmployees();

  return summary.copyWith(totalTeam: allRes.employees.length);
});

/// Daily progress provider — tasks due TODAY (for the "Today" progress ring).
final dashboardTodayTasksProvider =
    FutureProvider.autoDispose<DailyProgress>((ref) async {
      final dio = ref.watch(_dashboardDioProvider);
      final response = await dio.get(ApiConstant.dashboardTodayTasksEndpoint);
      return DailyProgress.fromJson(response.data as Map<String, dynamic>);
    });

/// Urgent tasks provider (High Priority & Pending)
final dashboardUrgentTasksProvider =
    FutureProvider.autoDispose<TasksListResponse>((ref) async {
      final dio = ref.watch(_dashboardDioProvider);
      final ds = TaskDataSourceImpl(dio);
      return await ds.getTasks(status: 'PENDING', priority: 'HIGH', limit: 3);
    });

/// Recent activity provider (Task History)
final dashboardActivityProvider =
    FutureProvider.autoDispose<TaskHistoryResponse>((ref) async {
      final dio = ref.watch(_dashboardDioProvider);
      final ds = TaskDataSourceImpl(dio);
      return await ds.getTaskHistory(limit: 5);
    });
