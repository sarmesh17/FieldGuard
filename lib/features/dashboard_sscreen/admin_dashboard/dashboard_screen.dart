import 'package:fieldguard/features/dashboard_sscreen/admin_dashboard/dashboard_topheader.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color _green = Color(0xFF0E5D3B);
  static const Color _orange = Color(0xFFF6A04D);
  static const Color _softOrange = Color(0xFFFFF4E4);
  static const Color _red = Color(0xFFFF3B3B);
  static const Color _softRed = Color(0xFFFFE3E6);
  static const Color _cardBorder = Color(0xFFE7DFD2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 430).clamp(0.85, 1.15);
            final contentWidth = constraints.maxWidth;

            return Column(
              children: [
                TopHeader(scale: scale),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: contentWidth,
                      color: const Color.fromARGB(255, 223, 238, 228),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _s(22, scale),
                          vertical: _s(18, scale),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sunday, 3 May 2026',
                                  style: TextStyle(
                                    fontSize: _s(18, scale),
                                    color: const Color(0xFFB1A7A0),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                _ZonePill(scale: scale),
                              ],
                            ),
                            SizedBox(height: _s(28, scale)),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatsCard(
                                    scale: scale,
                                    value: '12',
                                    label: 'Reps\nActive',
                                    valueColor: _green,
                                    backgroundColor: Colors.white,
                                    borderColor: _cardBorder,
                                  ),
                                ),
                                SizedBox(width: _s(14, scale)),
                                Expanded(
                                  child: _StatsCard(
                                    scale: scale,
                                    value: '8',
                                    label: 'Reps in\nField',
                                    valueColor: const Color(0xFF1F1F1F),
                                    backgroundColor: Colors.white,
                                    borderColor: _cardBorder,
                                  ),
                                ),
                                SizedBox(width: _s(14, scale)),
                                Expanded(
                                  child: _StatsCard(
                                    scale: scale,
                                    value: '3',
                                    label: 'Alerts',
                                    valueColor: _orange,
                                    backgroundColor: _softOrange,
                                    borderColor: Color(0xFFFFD7A3),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _s(32, scale)),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFF7B500),
                                  size: 28,
                                ),
                                SizedBox(width: _s(8, scale)),
                                Text(
                                  'Fraud Alerts',
                                  style: TextStyle(
                                    fontSize: _s(22, scale),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _s(16, scale),
                                    vertical: _s(7, scale),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _softRed,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '3 new',
                                    style: TextStyle(
                                      fontSize: _s(14, scale),
                                      color: _red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _s(14, scale)),
                            _AlertCard(
                              scale: scale,
                              accentColor: const Color(0xFFFF4343),
                              leadingIcon: Icons.sos_rounded,
                              leadingIconColor: const Color(0xFFFF4A2D),
                              title: 'Payment Disputed',
                              time: '2 min ago',
                              description:
                                  'Mehta Traders says Raj collected ₹20,000 but rep reported ₹15,000',
                              primaryActionLabel: 'Call Shopkeeper',
                              primaryActionColor: _green,
                              secondaryActionLabel: 'View Details',
                              secondaryActionColor: _red,
                              showSplitActions: true,
                            ),
                            SizedBox(height: _s(16, scale)),
                            _AlertCard(
                              scale: scale,
                              accentColor: const Color(0xFFFFA44D),
                              leadingIcon: Icons.warning_amber_rounded,
                              leadingIconColor: const Color(0xFFF7B500),
                              title: 'Drive-By Visit',
                              time: '18 min ago',
                              description:
                                  'Priya was at Gupta Store for only 1 min 12 sec',
                              primaryActionLabel: 'View Details',
                              primaryActionColor: const Color(0xFF111111),
                              secondaryActionLabel: '',
                              secondaryActionColor: Colors.transparent,
                              showSplitActions: false,
                            ),
                            SizedBox(height: _s(22, scale)),
                            Center(
                              child: Text(
                                'View All Alerts',
                                style: TextStyle(
                                  fontSize: _s(18, scale),
                                  color: _green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(height: _s(32, scale)),
                            Row(
                              children: [
                                Text(
                                  'Team Status',
                                  style: TextStyle(
                                    fontSize: _s(22, scale),
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'View All  →',
                                  style: TextStyle(
                                    fontSize: _s(16, scale),
                                    color: _green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _s(14, scale)),
                            _TeamStatusCard(scale: scale),
                            SizedBox(height: _s(22, scale)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _s(double value, double scale) => value * scale;
}

class _ZonePill extends StatelessWidget {
  const _ZonePill({required this.scale});

  final double scale;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _s(16), vertical: _s(7)),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF5E0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Kathmandu Zone',
        style: TextStyle(
          fontSize: _s(12),
          color: const Color(0xFF0E5D3B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.scale,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final double scale;
  final String value;
  final String label;
  final Color valueColor;
  final Color backgroundColor;
  final Color borderColor;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _s(172),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_s(16)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _s(10), vertical: _s(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: _s(38),
                height: 1.0,
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: _s(12)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _s(17),
                height: 1.1,
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.scale,
    required this.accentColor,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.title,
    required this.time,
    required this.description,
    required this.primaryActionLabel,
    required this.primaryActionColor,
    required this.secondaryActionLabel,
    required this.secondaryActionColor,
    required this.showSplitActions,
  });

  final double scale;
  final Color accentColor;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final String title;
  final String time;
  final String description;
  final String primaryActionLabel;
  final Color primaryActionColor;
  final String secondaryActionLabel;
  final Color secondaryActionColor;
  final bool showSplitActions;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(16)),
        border: Border.all(color: const Color(0xFFE9E2D7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: _s(6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(_s(16)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(_s(18), _s(18), _s(18), _s(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          leadingIcon,
                          color: leadingIconColor,
                          size: _s(30),
                        ),
                        SizedBox(width: _s(10)),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: _s(19),
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: _s(15),
                            color: const Color(0xFF9B948F),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _s(14)),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: _s(17),
                        height: 1.45,
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: _s(34)),
                    if (showSplitActions)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            primaryActionLabel,
                            style: TextStyle(
                              fontSize: _s(17),
                              color: primaryActionColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            secondaryActionLabel,
                            style: TextStyle(
                              fontSize: _s(17),
                              color: secondaryActionColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          primaryActionLabel,
                          style: TextStyle(
                            fontSize: _s(18),
                            color: primaryActionColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamStatusCard extends StatelessWidget {
  const _TeamStatusCard({required this.scale});

  final double scale;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_s(16)),
        border: Border.all(color: const Color(0xFFE9E2D7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _TeamRow(
            scale: scale,
            color: const Color(0xFF50B878),
            name: 'Rajesh Kumar',
            company: 'Mehta Traders',
            progress: '5/8 shops',
          ),
          Divider(height: 1, color: const Color(0xFFE7DFD2)),
          _TeamRow(
            scale: scale,
            color: const Color(0xFFF59D4C),
            name: 'Priya Sharma',
            company: 'Gupta Store',
            progress: '3/8 shops',
          ),
          Divider(height: 1, color: const Color(0xFFE7DFD2)),
          _TeamRow(
            scale: scale,
            color: const Color(0xFFA8A3A0),
            name: 'Amit Patel',
            company: 'Not Started',
            progress: '0/8 shops',
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.scale,
    required this.color,
    required this.name,
    required this.company,
    required this.progress,
  });

  final double scale;
  final Color color;
  final String name;
  final String company;
  final String progress;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _s(16), vertical: _s(15)),
      child: Row(
        children: [
          Container(
            width: _s(16),
            height: _s(16),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: _s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: _s(17),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _s(4)),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: _s(16),
                    color: const Color(0xFF6D7686),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            progress,
            style: TextStyle(
              fontSize: _s(16),
              color: const Color(0xFF0E5D3B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: _s(10)),
          Icon(
            Icons.chevron_right_rounded,
            size: _s(30),
            color: const Color(0xFF9F9690),
          ),
        ],
      ),
    );
  }
}
