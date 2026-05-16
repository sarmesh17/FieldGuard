import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/domain/repository/shops_repository.dart';

class ShopsRepositoryImpl implements ShopsRepository {
  final ShopsDataSource _dataSource;

  ShopsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<ShopWithCreator>>> getShopsWithCreators() async {
    try {
      final response = await _dataSource.getShopsHierarchy();
      final List<ShopWithCreator> shops = [];

      // Add unassigned shops (created by admin)
      for (final shop in response.unassignedShops) {
        shops.add(ShopWithCreator(
          shop: shop,
          creatorName: 'Admin',
          creatorRole: 'Admin',
          creatorCode: 'ADMIN',
        ));
      }

      // Add shops from managers
      for (final managerData in response.managers) {
        for (final shop in managerData.shops) {
          shops.add(ShopWithCreator(
            shop: shop,
            creatorName: managerData.manager.fullName,
            creatorRole: 'Manager',
            creatorCode: managerData.manager.employeeCode,
          ));
        }

        // Add shops from employees under this manager
        for (final employeeData in managerData.employees) {
          for (final shop in employeeData.shops) {
            shops.add(ShopWithCreator(
              shop: shop,
              creatorName: employeeData.employee.fullName,
              creatorRole: 'Employee',
              creatorCode: employeeData.employee.employeeCode,
            ));
          }
        }
      }

      // Add shops from direct employees
      for (final employeeData in response.directEmployees) {
        for (final shop in employeeData.shops) {
          shops.add(ShopWithCreator(
            shop: shop,
            creatorName: employeeData.employee.fullName,
            creatorRole: 'Employee',
            creatorCode: employeeData.employee.employeeCode,
          ));
        }
      }

      return Success(shops);
    } catch (e) {
      return Failure(ServerException('Failed to load shops'));
    }
  }
}
