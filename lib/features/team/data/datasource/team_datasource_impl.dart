import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/team/data/datasource/team_datasource.dart';
import 'package:fieldguard/features/team/data/dto/employee_detail_response.dart';
import 'package:fieldguard/features/team/data/dto/employees_list_response.dart';
import 'package:fieldguard/features/team/data/dto/manager_detail_response.dart';
import 'package:fieldguard/features/team/data/dto/managers_list_response.dart';

class TeamDataSourceImpl implements TeamDataSource {
  final Dio _dio;

  TeamDataSourceImpl(this._dio);

  @override
  Future<EmployeesListResponse> getEmployees() async {
    try {
      final response = await _dio.get(ApiConstant.getEmployeesEndpoint);
      return EmployeesListResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ManagersListResponse> getManagers() async {
    try {
      final response = await _dio.get(ApiConstant.getManagersEndpoint);
      return ManagersListResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EmployeeDetailResponse> getEmployeeDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstant.getEmployeesEndpoint}/$id');
      return EmployeeDetailResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ManagerDetailResponse> getManagerDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstant.getManagersEndpoint}/$id');
      return ManagerDetailResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
