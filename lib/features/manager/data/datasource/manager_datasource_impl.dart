import 'package:dio/dio.dart';
import 'package:fieldguard/core/constant/api_constant.dart';
import 'package:fieldguard/features/manager/data/datasource/manager_datasource.dart';
import 'package:fieldguard/features/manager/data/dto/create_manager_request.dart';
import 'package:fieldguard/features/manager/data/dto/create_manager_response.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_request.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_response.dart';

class ManagerDataSourceImpl implements ManagerDataSource {
  final Dio _dio;

  ManagerDataSourceImpl(this._dio);

  @override
  Future<CreateManagerResponse> createManager(
      CreateManagerRequest request) async {
    try {
      final jsonData = request.toJson();
      
      // Convert all values to strings for FormData
      final Map<String, dynamic> formDataMap = {};
      jsonData.forEach((key, value) {
        if (value != null) {
          formDataMap[key] = value.toString();
        }
      });
      
      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        ApiConstant.createManagerEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return CreateManagerResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UpdateManagerResponse> updateManager(
      String id, UpdateManagerRequest request) async {
    try {
      final response = await _dio.patch(
        '${ApiConstant.createManagerEndpoint}/$id',
        data: request.toJson(),
        options: Options(
          contentType: 'application/json',
        ),
      );

      return UpdateManagerResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteManager(String id) async {
    try {
      await _dio.delete('${ApiConstant.createManagerEndpoint}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
