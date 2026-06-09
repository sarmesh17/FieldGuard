import 'package:fieldguard/core/theme/app_colors.dart';
import 'package:fieldguard/features/notifications/data/notifications_response.dart';
import 'package:fieldguard/features/notifications/presentation/notification_router.dart';
import 'package:fieldguard/features/notifications/presentation/notifications_notifier.dart';
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
    // Always pull a fresh list on open — covers notifications delivered while
    // the app was backgrounded (the foreground stream doesn't see those).
    Future.microtask(
      () => ref.read(notificationsNotifierProvider.notifier).refresh(),
    );
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
    routeNotification(
      Navigator.of(context),
      kind: n.kind,
      shopId: n.shopId,
      taskId: n.taskId,
    );
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

/// Per-kind visual identity (icon + accent colour) for a notification tile.
class _NotifStyle {
  final IconData icon;
  final Color color;
  const _NotifStyle(this.icon, this.color);
}

_NotifStyle _styleFor(NotificationItem n) {
  switch (n.kind) {
    case 'COLLECTION_RECEIVED':
      final online = (n.method ?? '').toUpperCase() == 'ONLINE';
      return online
          ? const _NotifStyle(
              Icons.account_balance_wallet_rounded, AppColors.blue3)
          : const _NotifStyle(Icons.payments_rounded, AppColors.green5);
    case 'CHEQUE_RECEIVED':
      return const _NotifStyle(Icons.receipt_long_rounded, AppColors.orange2);
    case 'CHEQUE_CLEARED':
      return const _NotifStyle(Icons.verified_rounded, AppColors.green5);
    case 'CHEQUE_BOUNCED':
      // Needs action (re-collect from the shop) — flag it in alert red.
      return const _NotifStyle(Icons.warning_rounded, AppColors.red2);
    case 'TASK_ASSIGNED':
      return const _NotifStyle(Icons.assignment_rounded, AppColors.blue);
    default:
      return const _NotifStyle(Icons.notifications_rounded, _kBrand);
  }
}

String _methodLabel(String m) {
  switch (m.toUpperCase()) {
    case 'CASH':
      return 'Cash';
    case 'ONLINE':
      return 'Online';
    case 'CHEQUE':
      return 'Cheque';
    default:
      return m;
  }
}

/// Status pill text + colour, or null when there's nothing useful to show.
({String label, Color color})? _statusBadge(String? status) {
  switch (status?.toUpperCase()) {
    case 'PENDING':
      return (label: 'Pending', color: AppColors.orange2);
    case 'CLEARED':
      return (label: 'Cleared', color: AppColors.green5);
    case 'BOUNCED':
      return (label: 'Bounced', color: AppColors.red2);
    default:
      return null;
  }
}

/// "1500" / "1500.00" -> "1,500" (3-digit grouping). '' when unparseable.
String _formatAmount(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final n = num.tryParse(raw);
  if (n == null) return raw;
  final s = n.abs().truncate().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$buf';
}

class _Tile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _Tile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final style = _styleFor(item);
    final amount = _formatAmount(item.amount);
    final outstanding = _formatAmount(item.outstanding);
    final status = _statusBadge(item.status);
    final isCollection = item.kind == 'COLLECTION_RECEIVED' ||
        item.kind == 'CHEQUE_RECEIVED' ||
        item.kind == 'CHEQUE_CLEARED' ||
        item.kind == 'CHEQUE_BOUNCED';

    return Material(
      color: unread ? style.color.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread
                  ? style.color.withValues(alpha: 0.28)
                  : AppColors.grey4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, size: 22, color: style.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(top: 5, left: 8),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey, height: 1.4),
                      ),
                    ],
                    if (isCollection && amount.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _AmountChip(text: 'NPR $amount', color: style.color),
                          if (item.method != null && item.method!.isNotEmpty)
                            _MetaChip(label: _methodLabel(item.method!)),
                          if (status != null)
                            _MetaChip(
                                label: status.label, color: status.color),
                          if (outstanding.isNotEmpty && outstanding != '0')
                            _MetaChip(label: 'Due NPR $outstanding'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _relativeTime(item.createdAt),
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.grey9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prominent, accent-tinted amount pill (e.g. "NPR 1,500").
class _AmountChip extends StatelessWidget {
  final String text;
  final Color color;
  const _AmountChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Small outlined meta pill (method / status / outstanding).
class _MetaChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _MetaChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: c,
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
