import 'package:flutter/material.dart';

import 'components/notification_card.dart';

const _kBrand = Color(0xFF0E5A3B);
const _kBrandSoft = Color(0xFFD1FADF);
const _kBg = Color(0xFFF8FAF9);

/// Notifications inbox — filter chips on top, cards below. Currently driven
/// by hardcoded sample data (mirrors field_guard_re); plug a real feed in
/// once the backend exposes one. The mock copy is left identical so designs
/// reviewed against field_guard_re still line up here.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0;
  static const _filters = ['All', 'Alerts', 'Payments', 'Visits'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kBrand),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _kBrand,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: _kBrand,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips — scrollable for narrow screens.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = i == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        _filters[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      selected: selected,
                      selectedColor: _kBrand,
                      backgroundColor: _kBg,
                      side: selected
                          ? BorderSide.none
                          : const BorderSide(color: Color(0xFFE5E7EB)),
                      onSelected: (_) => setState(() => _selectedFilter = i),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                NotificationCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Color(0xFFDC2626),
                  iconBgColor: Color(0xFFFEE2E2),
                  borderColor: Color(0xFFDC2626),
                  title: 'Payment Disputed!',
                  description:
                      'Client #8902 has filed a dispute for the transaction on route 4B.',
                  time: 'Just now',
                ),
                SizedBox(height: 12),
                NotificationCard(
                  icon: Icons.access_time_rounded,
                  iconColor: Color(0xFFF59E0B),
                  iconBgColor: Color(0xFFFEF3C7),
                  borderColor: Color(0xFFF59E0B),
                  title: 'Short Visit Flagged',
                  description:
                      'Visit duration at Patel Electronics was below the 5-minute minimum threshold.',
                  time: '10m ago',
                ),
                SizedBox(height: 12),
                NotificationCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: Color(0xFF10B981),
                  iconBgColor: _kBrandSoft,
                  borderColor: Color(0xFF10B981),
                  title: 'Payment Confirmed — Sharma General Store',
                  description:
                      'Cash payment of ₹4,500 successfully logged and verified.',
                  time: '1h ago',
                ),
                SizedBox(height: 12),
                NotificationCard(
                  icon: Icons.map_outlined,
                  iconColor: Color(0xFF6B7280),
                  iconBgColor: Color(0xFFF3F4F6),
                  borderColor: Color(0xFF6B7280),
                  title: 'Route Updated by Manager',
                  description:
                      '2 new priority stops added to your afternoon schedule.',
                  time: '2h ago',
                ),
                SizedBox(height: 32),
                Center(
                  child: Text(
                    "You've caught up on all notifications.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
