import 'package:fieldguard/features/admin_profile/section_card.dart';
import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

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
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: Column(
                      children: [
                        SizedBox(height: hp(.03)),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: wp(.26),
                              height: wp(.26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff163C33),
                                  width: 2,
                                ),
                                image: const DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=800&auto=format&fit=crop',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -wp(.01),
                              bottom: -wp(.01),
                              child: Container(
                                width: wp(.11),
                                height: wp(.11),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.08),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: wp(.05),
                                  color: const Color(0xff0E5A3B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.03)),
                        Text(
                          'Alex Sterling',
                          style: TextStyle(
                            fontSize: wp(.095),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff111111),
                          ),
                        ),
                        SizedBox(height: hp(.008)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'alex.s@fieldops.inc',
                              style: TextStyle(
                                fontSize: wp(.05),
                                color: const Color(0xff667085),
                              ),
                            ),
                            SizedBox(width: wp(.02)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: wp(.03),
                                vertical: hp(.004),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffEEE9FF),
                                borderRadius: BorderRadius.circular(wp(.05)),
                                border: Border.all(
                                  color: const Color(0xffCFC3FF),
                                ),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  color: const Color(0xff6558FF),
                                  fontSize: wp(.04),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.035)),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: hp(.025)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(wp(.04)),
                            border: Border.all(color: const Color(0xffDDD6CE)),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                child: StatItem(value: '4', title: 'Managers'),
                              ),
                              StatDivider(),
                              Expanded(
                                child: StatItem(value: '24', title: 'Reps'),
                              ),
                              StatDivider(),
                              Expanded(
                                child: StatItem(value: '186', title: 'Shops'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: hp(.035)),
                        SectionCard(
                          title: 'ADMIN TOOLS',
                          highlighted: true,
                          items: const [
                            SectionTile(
                              icon: Icons.settings_outlined,
                              title: 'System Settings',
                              selected: true,
                            ),
                            SectionTile(
                              icon: Icons.receipt_long_outlined,
                              title: 'Audit Logs',
                            ),
                            SectionTile(
                              icon: Icons.download_outlined,
                              title: 'Backup & Export',
                            ),
                            SectionTile(
                              icon: Icons.gavel_outlined,
                              title: 'Fraud Rule Configuration',
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.03)),
                        SectionCard(
                          title: 'ACCOUNT',
                          items: const [
                            SectionTile(
                              icon: Icons.person_outline,
                              title: 'Personal Information',
                            ),
                            SectionTile(
                              icon: Icons.shield_outlined,
                              title: 'Security & Passwords',
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.06)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: wp(.065),
                            ),
                            SizedBox(width: wp(.02)),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: wp(.06),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.05)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatItem extends StatelessWidget {
  final String value;
  final String title;

  const StatItem({super.key, required this.value, required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: w * .075,
            fontWeight: FontWeight.w700,
            color: const Color(0xff0B5A39),
          ),
        ),
        SizedBox(height: w * .01),
        Text(
          title,
          style: TextStyle(fontSize: w * .042, color: const Color(0xff667085)),
        ),
      ],
    );
  }
}

class StatDivider extends StatelessWidget {
  const StatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: MediaQuery.of(context).size.width * .11,
      color: const Color(0xffDDD6CE),
    );
  }
}

class SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;

  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * .05, vertical: w * .045),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffECE7E1))),
      ),
      child: Row(
        children: [
          Container(
            width: w * .12,
            height: w * .12,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xffEEE9FF)
                  : const Color(0xffF1F2EE),
              borderRadius: BorderRadius.circular(w * .025),
            ),
            child: Icon(
              icon,
              color: selected
                  ? const Color(0xff635BFF)
                  : const Color(0xff667085),
              size: w * .065,
            ),
          ),
          SizedBox(width: w * .04),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: w * .055,
                fontWeight: FontWeight.w500,
                color: const Color(0xff111111),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: const Color(0xff9E978F),
            size: w * .08,
          ),
        ],
      ),
    );
  }
}
