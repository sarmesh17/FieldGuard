import 'package:dio/dio.dart';
import 'package:fieldguard/core/networks/dio_client.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource.dart';
import 'package:fieldguard/features/shops/data/datasource/shops_datasource_impl.dart';
import 'package:fieldguard/features/shops/data/repository/shops_repository_impl.dart';
import 'package:fieldguard/features/shops/domain/repository/shops_repository.dart';
import 'package:fieldguard/features/shops/domain/usecase/get_shops_usecase.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_notifier.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final shopsDioProvider = Provider<Dio>((ref) => DioClient.createDio());

final shopsDataSourceProvider = Provider<ShopsDataSource>(
  (ref) => ShopsDataSourceImpl(ref.watch(shopsDioProvider)),
);

final shopsRepositoryProvider = Provider<ShopsRepository>(
  (ref) => ShopsRepositoryImpl(ref.watch(shopsDataSourceProvider)),
);

final getShopsUsecaseProvider = Provider<GetShopsUsecase>(
  (ref) => GetShopsUsecase(ref.watch(shopsRepositoryProvider)),
);

final shopsNotifierProvider = StateNotifierProvider<ShopsNotifier, ShopsState>(
  (ref) => ShopsNotifier(ref.watch(getShopsUsecaseProvider)),
);
