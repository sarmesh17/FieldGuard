import 'package:fieldguard/features/shops/presentation/screens/shop_detail_screen.dart';
import 'package:fieldguard/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:flutter/material.dart';

/// Deep-links a notification (push tap OR in-app list tap) to its target
/// screen, by `data.kind`. Shared so both entry points behave identically.
///
/// All values are strings here (FCM sends strings; the in-app numbers are
/// normalised to strings on the [NotificationItem] getters).
void routeNotification(
  NavigatorState nav, {
  required String? kind,
  String? shopId,
  String? taskId,
}) {
  switch (kind) {
    // Every collection alert (cash/online/cheque + cleared/bounced) lands on
    // the shop detail screen, where the collection appears in the shop's list.
    case 'COLLECTION_RECEIVED':
    case 'CHEQUE_RECEIVED':
    case 'CHEQUE_CLEARED':
    case 'CHEQUE_BOUNCED':
      if (shopId != null && shopId.isNotEmpty) {
        nav.push(
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shopId)),
        );
      }
    case 'TASK_ASSIGNED':
      final id = int.tryParse(taskId ?? '');
      if (id != null) {
        nav.push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id)),
        );
      }
  }
}
