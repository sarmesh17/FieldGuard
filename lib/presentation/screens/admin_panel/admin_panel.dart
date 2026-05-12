import 'package:fieldguard/presentation/screens/admin_panel/admin_section.dart';
import 'package:fieldguard/presentation/screens/admin_panel/status_card.dart';
import 'package:fieldguard/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';


class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: const Color(0xffF7F5F1),
          bottomNavigationBar:BottomNavBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wp(.06),
                vertical: hp(.015),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: wp(.05),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff083D27),
                              ),
                            ),
                            SizedBox(width: wp(.025)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: wp(.025),
                                vertical: hp(.004),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffECE8FF),
                                borderRadius: BorderRadius.circular(wp(.03)),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: wp(.025),
                                  color: const Color(0xff635BFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.settings_outlined,
                        size: wp(.07),
                        color: const Color(0xff555555),
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.03)),
                  StatusCard(width: w, height: h),
                  SizedBox(height: hp(.025)),
                  AdminSection(
                    width: w,
                    title: 'People',
                    items: [
                      MenuItemData(
                        title: 'Register New Rep',
                        icon: Icons.person_add_alt_1_outlined,
                      ),
                      MenuItemData(
                        title: 'Manage Reps',
                        badge: '24 reps',
                      ),
                      MenuItemData(
                        title: 'Register New Manager',
                      ),
                      MenuItemData(
                        title: 'View All Users',
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.025)),
                  AdminSection(
                    width: w,
                    title: 'Shops',
                    accent: const Color(0xff5B4CFF),
                    items: [
                      MenuItemData(title: 'Register New Shop'),
                      MenuItemData(title: 'Set Shop GPS & Geofence'),
                      MenuItemData(
                        title: 'Generate NFC / QR Code',
                        icon: Icons.qr_code_2_outlined,
                        iconColor: const Color(0xff5B4CFF),
                      ),
                      MenuItemData(title: 'Assign Reps to Routes'),
                      MenuItemData(
                        title: 'View All Shops',
                        badge: '186 shops',
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.025)),
                  AdminSection(
                    width: w,
                    title: 'System Rules',
                    accent: const Color(0xff5B4CFF),
                    items: [
                      MenuItemData(
                        title: 'Minimum Visit Duration',
                        badge: '3 min',
                      ),
                      MenuItemData(
                        title: 'Geofence Radius',
                        badge: '75m',
                      ),
                      MenuItemData(title: 'SMS Templates'),
                      MenuItemData(title: 'Fraud Detection Rules'),
                      MenuItemData(
                        title:
                            'Payment Confirmation\nTimeout',
                        badge: '2\nhrs',
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.025)),
                  AdminSection(
                    width: w,
                    title: 'Reports & Audit',
                    items: [
                      MenuItemData(
                          title: 'Full System Audit Log'),
                      MenuItemData(title: 'Export All Data'),
                      MenuItemData(
                          title: 'Fraud History Report'),
                    ],
                  ),
                  SizedBox(height: hp(.03)),
                  DangerZone(width: w),
                  SizedBox(height: hp(.03)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
}

class StatusRow extends StatelessWidget {
  final String title;
  final String value;

  const StatusRow({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xff757575),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


class DangerZone extends StatelessWidget {
  final double width;

  const DangerZone({
    super.key,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      'Deactivate a Rep',
      'Reset Shop NFC Tag',
      'Wipe Daily Data',
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffFFF7F7),
        borderRadius: BorderRadius.circular(width * .04),
        border: Border.all(
          color: const Color(0xffFFB7B7),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * .05,
              vertical: width * .05,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: width * .04,
                  color: Colors.red,
                ),
                SizedBox(width: width * .02),
                Text(
                  'DANGER ZONE',
                  style: TextStyle(
                    fontSize: width * .028,
                    letterSpacing: 1.4,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(
            items.length,
            (index) => Column(
              children: [
                if (index != 0)
                  Divider(
                    height: 0,
                    color:
                        Colors.red.withOpacity(.12),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .05,
                    vertical: width * .05,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: width * .05),
                          child: Text(
                            items[index],
                            style: TextStyle(
                              fontSize: width * .04,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.red,
                        size: width * .06,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 0,
            color: Colors.red.withOpacity(.12),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * .05,
              vertical: width * .045,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: width * .035,
                  color: const Color(0xff9B9B9B),
                ),
                SizedBox(width: width * .025),
                Expanded(
                  child: Text(
                    'These actions cannot be undone. Use carefully.',
                    style: TextStyle(
                      fontSize: width * .032,
                      color: const Color(0xff9B9B9B),
                      height: 1.4,
                    ),
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

class MenuItemData {
  final String title;
  final String? badge;
  final IconData? icon;
  final Color? iconColor;

  MenuItemData({
    required this.title,
    this.badge,
    this.icon,
    this.iconColor,
  });
}