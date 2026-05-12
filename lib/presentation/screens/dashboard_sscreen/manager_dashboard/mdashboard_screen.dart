
import 'package:fieldguard/presentation/screens/dashboard_sscreen/manager_dashboard/admin_overview_card.dart';
import 'package:fieldguard/presentation/screens/dashboard_sscreen/manager_dashboard/mdashboard_header.dart';
import 'package:fieldguard/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 700;

        final horizontalPadding = isTablet ? 32.0 : 20.0;
        final cardSpacing = isTablet ? 24.0 : 16.0;

        return Scaffold(
          backgroundColor: const Color(0xffF7F5F2),
          bottomNavigationBar: BottomNavBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 700 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ManagerHeaderSection(),
                      const SizedBox(height: 28),

                      const _DateSection(),
                      const SizedBox(height: 28),

                      const _SectionTitle(title: "TODAY AT A GLANCE"),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _StatsCard(
                              icon: Icons.shopping_bag_outlined,
                              value: "12",
                              title: "SHOPS VISITED",
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: _StatsCard(
                              icon: Icons.nfc_outlined,
                              value: "8",
                              title: "NFC SCANS",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      _TitleActionRow(
                        title: "FRAUD ALERTS",
                        action: "View All",
                      ),

                      const SizedBox(height: 16),

                      const _FraudAlertCard(),

                      const SizedBox(height: 36),

                      _TitleActionRow(title: "TEAM STATUS", action: "Manage"),

                      const SizedBox(height: 18),

                      const _TeamStatusCard(
                        dotColor: Color(0xff4CB67A),
                        title: "Active Now",
                        value: "5 Reps",
                        valueColor: Color(0xff005C33),
                      ),

                      const SizedBox(height: 18),

                      const _TeamStatusCard(
                        dotColor: Color(0xffF2E1C5),
                        title: "Inactive > 2hrs",
                        value: "2 Reps",
                        valueColor: Color(0xff6C7485),
                      ),

                      const SizedBox(height: 36),

                      const AdminOverviewCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _DateSection extends StatelessWidget {
  const _DateSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S DATE",
          style: TextStyle(
            color: Color(0xff687184),
            letterSpacing: 1,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Wed, Oct 25",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xff005C33),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff687184),
        letterSpacing: 1,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _StatsCard({
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE8E1D7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff005C33), size: 32),
          const SizedBox(height: 28),
          Text(
            value,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Color(0xff005C33),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff687184),
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleActionRow extends StatelessWidget {
  final String title;
  final String action;

  const _TitleActionRow({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff687184),
            letterSpacing: 1,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: Color(0xff005C33),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xff005C33)),
          ],
        ),
      ],
    );
  }
}

class _FraudAlertCard extends StatelessWidget {
  const _FraudAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffECE4DB)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 165,
            decoration: const BoxDecoration(
              color: Color(0xffFF3347),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xffFFE5E6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xffFF3347),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fake Location Detected",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Raj Kumar flagged for GPS spoofing\nattempt at Shop #402.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xff687184),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamStatusCard extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String value;
  final Color valueColor;

  const _TeamStatusCard({
    required this.dotColor,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE8E1D7)),
      ),
      child: Row(
        children: [
          Container(
            height: 14,
            width: 14,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}




