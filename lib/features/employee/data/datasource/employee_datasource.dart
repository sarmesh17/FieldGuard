import 'package:fieldguard/features/employee/data/dto/create_employee_request.dart';
import 'package:fieldguard/features/employee/data/dto/create_employee_response.dart';
import 'package:fieldguard/features/employee/data/dto/update_employee_request.dart';
import 'package:fieldguard/features/employee/data/dto/update_employee_response.dart';

abstract class EmployeeDataSource {
  Future<CreateEmployeeResponse> createEmployee(CreateEmployeeRequest request);
  Future<UpdateEmployeeResponse> updateEmployee(String id, UpdateEmployeeRequest request);
  Future<void> deleteEmployee(String id);
}
