import 'package:flutter/material.dart';


class ManagerProfileScreen extends StatefulWidget {

  @override
  State<ManagerProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ManagerProfileScreen> {
  bool notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.06),
                      vertical: hp(.02),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: hp(.015)),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: wp(.23),
                              height: wp(.23),
                              decoration: const BoxDecoration(
                                color: Color(0xffCFE8D1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'AS',
                                style: TextStyle(
                                  fontSize: wp(.08),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff16603D),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: 4,
                              child: Container(
                                width: wp(.08),
                                height: wp(.08),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xffE5E1DA),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.06),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: wp(.04),
                                  color: const Color(0xff666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.02)),
                        Text(
                          'Arjun Singh',
                          style: TextStyle(
                            fontSize: wp(.07),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: hp(.008)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: wp(.03),
                            vertical: hp(.004),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffD7EED8),
                            borderRadius: BorderRadius.circular(wp(.05)),
                          ),
                          child: Text(
                            'MANAGER',
                            style: TextStyle(
                              fontSize: wp(.028),
                              letterSpacing: 1,
                              color: const Color(0xff16603D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: hp(.012)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: wp(.04),
                              color: const Color(0xff9B948A),
                            ),
                            SizedBox(width: wp(.01)),
                            Text(
                              'Kathmandu Zone',
                              style: TextStyle(
                                fontSize: wp(.04),
                                color: const Color(0xff9B948A),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.03)),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                width: w,
                                value: '24',
                                label: 'Reps\nManaged',
                              ),
                            ),
                            SizedBox(width: wp(.035)),
                            Expanded(
                              child: StatCard(
                                width: w,
                                value: '186',
                                label: 'Shops\nin Zone',
                              ),
                            ),
                            SizedBox(width: wp(.035)),
                            Expanded(
                              child: StatCard(
                                width: w,
                                value: '96%',
                                label: 'Team\nConfirm\nRate',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.025)),
                        SectionCard(
                          width: w,
                          title: 'My Account',
                          children: [
                            TileItem(
                              width: w,
                              icon: Icons.person_outline,
                              title: 'My Information',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.notifications_none,
                              title: 'Notification Preferences',
                              trailing: Transform.scale(
                                scale: .8,
                                child: Switch(
                                  value: notificationEnabled,
                                  activeColor: Colors.white,
                                  activeTrackColor:
                                      const Color(0xff0D6B3E),
                                  onChanged: (v) {
                                    setState(() {
                                      notificationEnabled = v;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.02)),
                        SectionCard(
                          width: w,
                          title: 'Zone Management',
                          children: [
                            TileItem(
                              width: w,
                              icon: Icons.groups_2_outlined,
                              title: 'My Team',
                              subtitle: '24 reps',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.storefront_outlined,
                              title: 'Assigned Shops',
                              subtitle: '186 shops',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.map_outlined,
                              title: 'Route Planning',
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.02)),
                        SectionCard(
                          width: w,
                          title: 'Reports',
                          children: [
                            TileItem(
                              width: w,
                              icon: Icons.calendar_today_outlined,
                              title: 'Weekly Summary',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.calendar_month_outlined,
                              title: 'Monthly Report',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.download_outlined,
                              title: 'Export Data',
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.02)),
                        SectionCard(
                          width: w,
                          title: 'App',
                          children: [
                            TileItem(
                              width: w,
                              icon: Icons.info_outline,
                              title: 'App Version',
                              subtitle: 'v1.0.0',
                              hideArrow: true,
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.help_outline,
                              title: 'Help & FAQs',
                            ),
                            TileItem(
                              width: w,
                              icon: Icons.support_agent_outlined,
                              title: 'Contact Admin',
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.05)),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: wp(.05),
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: hp(.05)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.symmetric(vertical: hp(.012)),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xffECE7DF)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomItem(
                  width: w,
                  icon: Icons.home_outlined,
                  label: 'Home',
                ),
                BottomItem(
                  width: w,
                  icon: Icons.groups_2_outlined,
                  label: 'Team',
                ),
                BottomItem(
                  width: w,
                  icon: Icons.notifications_none,
                  label: 'Alerts',
                ),
                BottomItem(
                  width: w,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payments',
                ),
                BottomItem(
                  width: w,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  active: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final double width;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.width,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: width * .05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .035),
        border: Border.all(color: const Color(0xffE9E4DC)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: width * .07,
              fontWeight: FontWeight.w700,
              color: const Color(0xff0A5A37),
            ),
          ),
          SizedBox(height: width * .015),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * .032,
              color: const Color(0xff666666),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final double width;
  final String title;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.width,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
        border: Border.all(color: const Color(0xffE8E2D9)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: width * .055,
              vertical: width * .05,
            ),
            decoration: const BoxDecoration(
              color: Color(0xffF3F3F0),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: width * .05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class TileItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool hideArrow;
  final Widget? trailing;

  const TileItem({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    this.subtitle,
    this.hideArrow = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .055,
        vertical: width * .045,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xffEFE9E1)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: width * .06,
            color: const Color(0xff61677A),
          ),
          SizedBox(width: width * .04),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: width * .045,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(right: width * .03),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: width * .033,
                  color: const Color(0xff9A948B),
                ),
              ),
            ),
          if (trailing != null)
            trailing!
          else if (!hideArrow)
            Icon(
              Icons.chevron_right,
              size: width * .06,
              color: const Color(0xff707070),
            ),
        ],
      ),
    );
  }
}

class BottomItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool active;

  const BottomItem({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? const Color(0xff0A6B3F) : const Color(0xff9A948B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: width * .06,
          color: color,
        ),
        SizedBox(height: width * .01),
        Text(
          label,
          style: TextStyle(
            fontSize: width * .03,
            color: color,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}