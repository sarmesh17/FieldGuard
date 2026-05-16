import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/shops/data/datasource/update_shop_datasource.dart';
import 'package:fieldguard/features/shops/data/datasource/update_shop_datasource_impl.dart';
import 'package:fieldguard/features/shops/presentation/providers/update_shop_notifier.dart';
import 'package:fieldguard/features/shops/presentation/providers/update_shop_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final updateShopDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final updateShopDataSourceProvider = Provider<UpdateShopDataSource>(
  (ref) => UpdateShopDataSourceImpl(ref.watch(updateShopDioProvider)),
);

final updateShopNotifierProvider =
    StateNotifierProvider.autoDispose<UpdateShopNotifier, UpdateShopState>(
  (ref) => UpdateShopNotifier(ref.watch(updateShopDataSourceProvider)),
);
