import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/employee/data/datasource/employee_datasource.dart';
import 'package:fieldguard/features/employee/data/dto/create_employee_request.dart';
import 'package:fieldguard/features/employee/data/dto/create_employee_response.dart';
import 'package:fieldguard/features/employee/data/dto/update_employee_request.dart';
import 'package:fieldguard/features/employee/data/dto/update_employee_response.dart';

class EmployeeDataSourceImpl implements EmployeeDataSource {
  final Dio _dio;

  EmployeeDataSourceImpl(this._dio);

  @override
  Future<CreateEmployeeResponse> createEmployee(
      CreateEmployeeRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstant.createEmployeeEndpoint,
        data: request.toJson(),
        options: Options(
          contentType: 'application/json',
        ),
      );

      return CreateEmployeeResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UpdateEmployeeResponse> updateEmployee(
      String id, UpdateEmployeeRequest request) async {
    try {
      final response = await _dio.patch(
        '${ApiConstant.createEmployeeEndpoint}/$id',
        data: request.toJson(),
        options: Options(
          contentType: 'application/json',
        ),
      );

      return UpdateEmployeeResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      await _dio.delete('${ApiConstant.createEmployeeEndpoint}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
