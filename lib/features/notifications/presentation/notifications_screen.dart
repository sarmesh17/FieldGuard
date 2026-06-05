import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/features/notifications/data/notifications_response.dart';
import 'package:fieldguard/features/notifications/presentation/notifications_notifier.dart';
import 'package:fieldguard/features/shops/presentation/screens/shop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kBrand = AppColors.green;

/// In-app notification center. Lists `GET /api/v1/notifications`, marks items
/// read on tap, and deep-links a CHEQUE_RECEIVED notification to its shop.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 300) {
        ref.read(notificationsNotifierProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onTap(NotificationItem n) {
    ref.read(notificationsNotifierProvider.notifier).markRead(n.id);
    final shopId = n.shopId;
    if (n.kind == 'CHEQUE_RECEIVED' && shopId != null && shopId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shopId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (state.loading && state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: _kBrand),
            );
          }
          if (state.error != null && state.items.isEmpty) {
            return _ErrorRetry(message: state.error!, onRetry: notifier.refresh);
          }
          if (state.items.isEmpty) return const _Empty();
          return RefreshIndicator(
            color: _kBrand,
            onRefresh: notifier.refresh,
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: _kBrand),
                      ),
                    ),
                  );
                }
                final item = state.items[i];
                return _Tile(item: item, onTap: () => _onTap(item));
              },
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _Tile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Material(
      color: unread ? _kBrand.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_rounded,
                    size: 20, color: _kBrand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt),
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.grey9),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 9,
                  height: 9,
                  decoration:
                      const BoxDecoration(color: _kBrand, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 44, color: AppColors.grey9),
          SizedBox(height: 12),
          Text('No notifications yet',
              style: TextStyle(fontSize: 14, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.grey2),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}

/// Short relative time (e.g. "5m", "2h", "3d") from an ISO timestamp.
String _relativeTime(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
