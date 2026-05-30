import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/networks/dio_client.dart';
import '../../../../core/services/session.dart';
import '../../../../core/utils/results.dart';
import '../../../shops/presentation/providers/shops_provider.dart';
import '../../../team/data/datasource/team_datasource_impl.dart';

/// Real counts shown on the Admin Profile stats card.
///
/// A `null` field means that count failed to load (or isn't applicable, e.g.
/// managers for a MANAGER user) — the UI renders it as a dash instead of a
/// fabricated number.
class ProfileStats {
  final int? managers;
  final int? reps;
  final int? shops;

  const ProfileStats({this.managers, this.reps, this.shops});

  static const empty = ProfileStats();
}

sealed class ProfileStatsState {
  const ProfileStatsState();
}

class ProfileStatsLoading extends ProfileStatsState {
  const ProfileStatsLoading();
}

class ProfileStatsLoaded extends ProfileStatsState {
  final ProfileStats stats;
  const ProfileStatsLoaded(this.stats);
}

class ProfileStatsNotifier extends StateNotifier<ProfileStatsState> {
  ProfileStatsNotifier(this._ref) : super(const ProfileStatsLoading());

  final Ref _ref;

  Future<void> fetch() async {
    state = const ProfileStatsLoading();

    final isManager = await Session.isManager();
    final teamDataSource = TeamDataSourceImpl(DioClient.createDio());

    // Fire all calls together. Each is independently guarded so one failure
    // doesn't blank out the others — a missing count just shows as a dash.
    final repsFuture = _safeCount(() async {
      final res = await teamDataSource.getEmployees();
      return res.employees.length;
    });

    // The list-managers API is admin-only; a manager has no manager count.
    final managersFuture = isManager
        ? Future<int?>.value(null)
        : _safeCount(() async {
            final res = await teamDataSource.getManagers();
            return res.managers.length;
          });

    final shopsFuture = _safeCount(() async {
      final result = await _ref.read(getShopsUsecaseProvider)();
      return switch (result) {
        Success(:final data) => data.length,
        Failure() => throw Exception('shops failed'),
      };
    });

    final results = await Future.wait([repsFuture, managersFuture, shopsFuture]);

    if (!mounted) return;
    state = ProfileStatsLoaded(
      ProfileStats(
        reps: results[0],
        managers: results[1],
        shops: results[2],
      ),
    );
  }

  Future<int?> _safeCount(Future<int> Function() call) async {
    try {
      return await call();
    } catch (_) {
      return null;
    }
  }
}

final profileStatsNotifierProvider =
    StateNotifierProvider<ProfileStatsNotifier, ProfileStatsState>(
  (ref) => ProfileStatsNotifier(ref),
);
