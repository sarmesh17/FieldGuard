import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource.dart';
import 'package:fieldguard/features/shops/domain/models/shop_with_creator.dart';
import 'package:fieldguard/features/shops/domain/repository/shops_repository.dart';

class ShopsRepositoryImpl implements ShopsRepository {
  final ShopsDataSource _dataSource;

  ShopsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<ShopWithCreator>>> getShopsWithCreators({String? source}) async {
    try {
      final response = await _dataSource.getShopsHierarchy(source: source);
      final List<ShopWithCreator> shops = [];

      // New flat shape with source filter: use creator info from shops.
      // Old grouped shape: reconstruct from hierarchy.
      final isFiltered = source != null;

      if (isFiltered) {
        // Source filter was used — all shops are in myShops with creator info.
        for (final shop in response.myShops) {
          if (shop.creator != null) {
            shops.add(ShopWithCreator(
              shop: shop,
              creatorName: shop.creator!.fullName,
              creatorRole: shop.creator!.role,
              creatorCode: shop.creator!.code,
            ));
          }
        }
      } else {
        // No filter — use the old grouped response structure.

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

        // Manager view: the API returns a different envelope — the manager's
        // own shops plus their team's shops.
        for (final shop in response.myShops) {
          shops.add(ShopWithCreator(
            shop: shop,
            creatorName: 'You',
            creatorRole: 'Manager',
            creatorCode: 'ME',
          ));
        }
        for (final employeeData in response.team) {
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

      return Success(shops);
    } catch (e) {
      return Failure(ServerException('Failed to load shops'));
    }
  }
}
