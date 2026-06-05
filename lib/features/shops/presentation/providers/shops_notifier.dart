import 'package:fieldguard/core/constant/app_strings.dart';
import 'package:fieldguard/core/errors/app_exception.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/shops/domain/usecase/get_shops_usecase.dart';
import 'package:fieldguard/features/shops/presentation/providers/shops_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class ShopsNotifier extends StateNotifier<ShopsState> {
  final GetShopsUsecase _getShopsUsecase;

  ShopsNotifier(this._getShopsUsecase) : super(const ShopsInitial());

  Future<void> loadShops({String? source}) async {
    state = const ShopsLoading();

    final result = await _getShopsUsecase(source: source);

    state = switch (result) {
      Success(:final data) => ShopsSuccess(data),
      Failure(:final exception) => ShopsFailure(
          exception is AppException ? exception.message : AppStrings.serverError,
        ),
    };
  }

  void reset() {
    state = const ShopsInitial();
  }
}
