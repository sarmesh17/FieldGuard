import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/utils/results.dart';
import 'package:fieldguard/features/collections/data/dto/set_shop_due_request.dart';
import 'package:fieldguard/features/collections/data/dto/collections_list_response.dart';
import 'package:fieldguard/features/collections/data/dto/create_collection_response.dart';
import 'package:fieldguard/features/collections/presentation/providers/collection_provider.dart';
import 'package:fieldguard/features/collections/presentation/providers/collections_list_state.dart';
import 'package:fieldguard/features/collections/presentation/screens/collection_success_screen.dart';
import 'package:fieldguard/features/collections/presentation/screens/components/settle_collection_sheet.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

const _kBrand = AppColors.green;
const _kInk = AppColors.black;
const _kMuted = AppColors.grey;

/// Collections list for a single shop, embedded in the shop detail screen.
/// `shopId` is fixed; filters here narrow status / method / date range. Lives
/// inside the parent's SingleChildScrollView, so it renders inline (shrink-
/// wrapped) and auto-loads the next page when the last row is built.
///
/// ADMIN/MANAGER additionally get a Settle action on PENDING cheque rows.
class ShopCollectionsSection extends ConsumerStatefulWidget {
  final int shopId;

  const ShopCollectionsSection({super.key, required this.shopId});

  @override
  ConsumerState<ShopCollectionsSection> createState() =>
      _ShopCollectionsSectionState();
}

class _ShopCollectionsSectionState
    extends ConsumerState<ShopCollectionsSection> {
  bool _canSettle = false;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    final role = (await Session.role())?.toUpperCase();
    if (!mounted) return;
    setState(() => _canSettle = role == 'ADMIN' || role == 'MANAGER');
  }

  /// Opens the settle sheet for a PENDING cheque; on success shows the result
  /// screen and refreshes the list so the row flips to CLEARED/BOUNCED.
  Future<void> _settle(CollectionRecord item) async {
    final result = await showModalBottomSheet<CreateCollectionResponse>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettleCollectionSheet(
        collectionId: item.id,
        amount: _fmtAmount(item.amount),
        chequeNumber: item.chequeNumber,
      ),
    );
    if (result == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionSuccessScreen(response: result),
      ),
    );
    if (!mounted) return;
    // Settling changes both the list (row status) and the money snapshot.
    ref.read(shopCollectionsProvider(widget.shopId).notifier).load();
    ref.invalidate(shopOutstandingProvider(widget.shopId));
  }

  @override
  Widget build(BuildContext context) {
    final shopId = widget.shopId;
    final state = ref.watch(shopCollectionsProvider(shopId));
    final notifier = ref.read(shopCollectionsProvider(shopId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutstandingBanner(shopId: shopId, canSetDue: _canSettle),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, size: 20, color: _kBrand),
            const SizedBox(width: 8),
            const Text(
              'Collections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const Spacer(),
            if (state is CollectionsListSuccess)
              Text(
                '${state.pagination.total} total',
                style: const TextStyle(fontSize: 12.5, color: _kMuted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _FilterBar(
          filters: _filtersOf(state),
          onChanged: notifier.applyFilters,
        ),
        const SizedBox(height: 12),
        switch (state) {
          CollectionsListInitial() ||
          CollectionsListLoading() =>
            const _LoadingBlock(),
          CollectionsListFailure(:final message) => _ErrorBlock(
              message: message,
              onRetry: notifier.load,
            ),
          CollectionsListSuccess() => _SuccessBlock(
              state: state,
              onLoadMore: notifier.loadMore,
              canSettle: _canSettle,
              onSettle: _settle,
            ),
        },
      ],
    );
  }

  CollectionFilters _filtersOf(CollectionsListState s) => switch (s) {
        CollectionsListSuccess(:final filters) => filters,
        CollectionsListFailure(:final filters) => filters,
        _ => const CollectionFilters(),
      };
}

// ─── Outstanding banner ───────────────────────────────────────────────────────

/// Shop money snapshot from `GET /collections/shops/{shopId}/outstanding`.
/// Independent of the collections list — its own fetch. The big number is the
/// outstanding (total_due − cleared); pending cheques are shown separately
/// since they don't reduce outstanding until cleared.
class _OutstandingBanner extends ConsumerWidget {
  final int shopId;
  final bool canSetDue;

  const _OutstandingBanner({required this.shopId, this.canSetDue = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopOutstandingProvider(shopId));
    return async.when(
      loading: () => const _BannerShell(child: _BannerLoading()),
      error: (_, _) => _BannerShell(
        child: _BannerError(
          onRetry: () => ref.invalidate(shopOutstandingProvider(shopId)),
        ),
      ),
      data: (snap) => _BannerShell(
        child: _BannerData(
          snapshot: snap,
          canSetDue: canSetDue,
          onSetDue: canSetDue
              ? () async {
                  final updated =
                      await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _SetDueSheet(
                      shopId: shopId,
                      currentDue: snap.totalDue,
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(shopOutstandingProvider(shopId));
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  final Widget child;
  const _BannerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBrand, AppColors.green],
        ),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BannerData extends StatelessWidget {
  final OutstandingSnapshot snapshot;
  final bool canSetDue;
  final VoidCallback? onSetDue;
  const _BannerData({
    required this.snapshot,
    this.canSetDue = false,
    this.onSetDue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OUTSTANDING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            if (canSetDue && onSetDue != null)
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onSetDue,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Set Due',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'NPR ${_fmtAmount(snapshot.outstanding)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _BannerStat(
              label: 'Total due',
              value: snapshot.totalDue,
            ),
            _bannerDivider(),
            _BannerStat(
              label: 'Collected',
              value: snapshot.collected,
            ),
            _bannerDivider(),
            _BannerStat(
              label: 'Pending',
              value: snapshot.pendingCheques,
            ),
          ],
        ),
      ],
    );
  }

  Widget _bannerDivider() => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.20),
      );
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _fmtAmount(value),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerLoading extends StatelessWidget {
  const _BannerLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
        ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  final VoidCallback onRetry;
  const _BannerError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Couldn't load the money snapshot.",
            style: TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Retry',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Filters ────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final CollectionFilters filters;
  final ValueChanged<CollectionFilters> onChanged;

  const _FilterBar({required this.filters, required this.onChanged});

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = (filters.from != null && filters.to != null)
        ? DateTimeRange(
            start: DateTime.tryParse(filters.from!) ??
                now.subtract(const Duration(days: 7)),
            end: DateTime.tryParse(filters.to!) ?? now,
          )
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked != null) {
      // Cover the whole end day by pushing 'to' to end-of-day.
      final from = DateTime(
        picked.start.year, picked.start.month, picked.start.day,
      ).toUtc().toIso8601String();
      final to = DateTime(
        picked.end.year, picked.end.month, picked.end.day, 23, 59, 59,
      ).toUtc().toIso8601String();
      onChanged(filters.copyWith(from: from, to: to));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = filters.from != null && filters.to != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              label: 'All',
              selected: filters.status == null,
              onTap: () => onChanged(filters.copyWith(status: null)),
            ),
            _Chip(
              label: 'Pending',
              selected: filters.status == 'PENDING',
              onTap: () => onChanged(filters.copyWith(status: 'PENDING')),
            ),
            _Chip(
              label: 'Cleared',
              selected: filters.status == 'CLEARED',
              onTap: () => onChanged(filters.copyWith(status: 'CLEARED')),
            ),
            _Chip(
              label: 'Bounced',
              selected: filters.status == 'BOUNCED',
              onTap: () => onChanged(filters.copyWith(status: 'BOUNCED')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Method + date range row
        Row(
          children: [
            _Chip(
              label: 'Cash',
              selected: filters.method == 'CASH',
              onTap: () => onChanged(
                filters.copyWith(
                  method: filters.method == 'CASH' ? null : 'CASH',
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Cheque',
              selected: filters.method == 'CHEQUE',
              onTap: () => onChanged(
                filters.copyWith(
                  method: filters.method == 'CHEQUE' ? null : 'CHEQUE',
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => _pickRange(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasRange ? _kBrand.withValues(alpha: 0.10) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasRange ? _kBrand : AppColors.grey7,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_rounded,
                        size: 15,
                        color: hasRange ? _kBrand : _kMuted),
                    const SizedBox(width: 5),
                    Text(
                      hasRange ? 'Dated' : 'Date',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: hasRange ? _kBrand : _kMuted,
                      ),
                    ),
                    if (hasRange) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            onChanged(filters.copyWith(from: null, to: null)),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: _kBrand),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kBrand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kBrand : AppColors.grey7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Success block (summary + list) ──────────────────────────────────────────────

class _SuccessBlock extends StatelessWidget {
  final CollectionsListSuccess state;
  final VoidCallback onLoadMore;
  final bool canSettle;
  final ValueChanged<CollectionRecord> onSettle;

  const _SuccessBlock({
    required this.state,
    required this.onLoadMore,
    required this.canSettle,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(summary: state.summary),
        const SizedBox(height: 14),
        if (state.items.isEmpty)
          const _EmptyBlock()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              // Auto-paginate: kick off the next page as the last row builds.
              if (i == state.items.length - 1 &&
                  state.hasMore &&
                  !state.loadingMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
              }
              final item = state.items[i];
              // Settleable: ADMIN/MANAGER + PENDING cheque only.
              final settleable = canSettle &&
                  item.method == 'CHEQUE' &&
                  item.status == 'PENDING';
              return _CollectionTile(
                item: item,
                onSettle: settleable ? () => onSettle(item) : null,
              );
            },
          ),
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: _kBrand),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CollectionsSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey12),
      ),
      child: Row(
        children: [
          _SummaryCell(
            label: 'Cleared',
            value: summary.cleared,
            color: _kBrand,
          ),
          _divider(),
          _SummaryCell(
            label: 'Pending',
            value: summary.pending,
            color: AppColors.brown,
          ),
          _divider(),
          _SummaryCell(
            label: 'Bounced',
            value: summary.bounced,
            color: AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: AppColors.white4,
      );
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _kMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'NPR ${_fmtAmount(value)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final CollectionRecord item;

  /// Non-null only when this row is settleable by the current user
  /// (ADMIN/MANAGER + PENDING cheque). Renders the Settle button.
  final VoidCallback? onSettle;

  const _CollectionTile({required this.item, this.onSettle});

  Color get _statusColor => switch (item.status) {
        'CLEARED' => _kBrand,
        'PENDING' => AppColors.brown,
        'BOUNCED' => AppColors.red,
        _ => _kMuted,
      };

  IconData get _methodIcon => item.method == 'CHEQUE'
      ? Icons.receipt_long_rounded
      : Icons.payments_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_methodIcon, size: 20, color: _statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'NPR ${_fmtAmount(item.amount)}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                        ),
                      ),
                    ),
                    _StatusBadge(status: item.status, color: _statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.method == 'CHEQUE' ? 'Cheque' : 'Cash'} · '
                  '${item.collector.fullName}',
                  style: const TextStyle(fontSize: 12.5, color: _kMuted),
                ),
                if (item.method == 'CHEQUE' &&
                    item.chequeNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Cheque #${item.chequeNumber}'
                    '${item.chequeBank != null ? ' · ${item.chequeBank}' : ''}',
                    style: const TextStyle(fontSize: 11.5, color: _kMuted),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _fmtDateTime(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.grey11),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.grey10,
                      height: 1.35,
                    ),
                  ),
                ],
                if (onSettle != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onSettle,
                      icon: const Icon(Icons.fact_check_rounded, size: 16),
                      label: const Text('Settle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBrand,
                        side: const BorderSide(color: _kBrand),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static String _label(String s) => switch (s) {
        'CLEARED' => 'Cleared',
        'PENDING' => 'Pending',
        'BOUNCED' => 'Bounced',
        _ => s,
      };
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: _kBrand),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 30, color: AppColors.grey11),
          SizedBox(height: 8),
          Text(
            'No collections match these filters',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red7),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.red9),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBrand,
              side: const BorderSide(color: _kBrand),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatting helpers ────────────────────────────────────────────────────────

String _fmtAmount(String raw) {
  final n = double.tryParse(raw) ?? 0;
  final fixed = n.toStringAsFixed(2);
  final parts = fixed.split('.');
  final buf = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
    buf.write(parts[0][i]);
  }
  return '$buf.${parts[1]}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtDateTime(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final meridiem = dt.hour < 12 ? 'AM' : 'PM';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} · '
      '$hour12:$minute $meridiem';
}

// ─── Set Due bottom sheet ──────────────────────────────────────────────────────

/// Bottom sheet that lets an ADMIN/MANAGER set or adjust a shop's total due.
/// On success, pops `true` so the caller can refresh the outstanding banner.
class _SetDueSheet extends ConsumerStatefulWidget {
  final int shopId;
  final String currentDue;

  const _SetDueSheet({required this.shopId, required this.currentDue});

  @override
  ConsumerState<_SetDueSheet> createState() => _SetDueSheetState();
}

class _SetDueSheetState extends ConsumerState<_SetDueSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dueCtrl;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the current total due (strip commas for clean editing).
    final cleaned = widget.currentDue.replaceAll(',', '');
    final n = double.tryParse(cleaned);
    _dueCtrl = TextEditingController(
      text: n != null ? n.toStringAsFixed(2) : cleaned,
    );
  }

  @override
  void dispose() {
    _dueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_dueCtrl.text.trim());
    setState(() {
      _submitting = true;
      _error = null;
    });

    final usecase = ref.read(setShopDueUsecaseProvider);
    final result = await usecase(
      widget.shopId,
      SetShopDueRequest(totalDue: amount),
    );

    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failure(:final exception):
        setState(() {
          _submitting = false;
          _error = exception.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + kb),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.blue13,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'Set Total Due',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Current total due: NPR ${_fmtAmount(widget.currentDue)}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 18),
            const Text(
              'New Total Due (NPR)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dueCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,12}(\.\d{0,2})?'),
                ),
              ],
              decoration: InputDecoration(
                hintText: 'e.g. 50000.00',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.grey9,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey7),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey7),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBrand, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.red, width: 1.5),
                ),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Amount is required';
                final n = double.tryParse(t);
                if (n == null) return 'Enter a valid amount';
                if (n < 0) return 'Amount cannot be negative';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red6,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red7),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.red9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update Due',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
