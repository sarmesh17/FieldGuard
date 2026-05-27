import 'package:fieldguard/features/team/data/dto/employee_detail_response.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/live_employees_response.dart';
import 'package:fieldguard/features/team/data/dto/manager_detail_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';

abstract class TeamDataSource {
  Future<EmployeesListResponse> getEmployees();
  Future<ManagersListResponse> getManagers();
  Future<EmployeeDetailResponse> getEmployeeDetail(String id);
  Future<ManagerDetailResponse> getManagerDetail(String id);

  /// Live/online employees (Redis-backed).
  // NOTE: when a managers/live endpoint lands, add `getLiveManagers()` here
  // and the online rail will be able to merge both with no UI rework.
  Future<LiveEmployeesResponse> getLiveEmployees();
}
