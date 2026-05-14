import 'package:fieldguard/features/manager/data/dto/create_manager_request.dart';
import 'package:fieldguard/features/manager/data/dto/create_manager_response.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_request.dart';
import 'package:fieldguard/features/manager/data/dto/update_manager_response.dart';

abstract class ManagerDataSource {
  Future<CreateManagerResponse> createManager(CreateManagerRequest request);
  Future<UpdateManagerResponse> updateManager(String id, UpdateManagerRequest request);
  Future<void> deleteManager(String id);
}
