
import 'package:fieldguard/presentation/screens/alert_notification_screen/alert_card.dart';
import 'package:fieldguard/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';



class AlertsNotificationScreen extends StatelessWidget {

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
          bottomNavigationBar: BottomNavBar(),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wp(.06)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: hp(.03)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Alerts & Notifications',
                          style: TextStyle(
                            fontSize: wp(.06),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: wp(.05),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff0B5D38),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.03)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChipWidget(
                          width: w,
                          title: 'All',
                          active: true,
                        ),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(
                          width: w,
                          title: 'Fraud',
                        ),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(
                          width: w,
                          title: 'Visits',
                        ),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(
                          width: w,
                          title: 'Payments',
                        ),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(
                          width: w,
                          title: 'System',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.03)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AlertCard(
                            width: w,
                            title: 'Payment Dispute — ...',
                            subtitle:
                                'Shopkeeper reported ₹5,000\ndiscrepancy',
                            actionText: 'Tap to resolve →',
                            time: '2 min ago',
                            icon: Icons.gavel_rounded,
                            sideColor:
                                const Color(0xffFF334B),
                            iconBg:
                                const Color(0xffFFE6E8),
                            iconColor:
                                const Color(0xffFF334B),
                            dotColor:
                                const Color(0xffFF334B),
                            timeColor:
                                const Color(0xffFF334B),
                            showAction: true,
                          ),
                          SizedBox(height: hp(.02)),
                          AlertCard(
                            width: w,
                            title: 'Short Visit — Priya a...',
                            subtitle:
                                'Visit lasted only 1 min 12 sec',
                            time: '18 min ago',
                            icon: Icons.timer_off_outlined,
                            sideColor:
                                const Color(0xffFFA552),
                            iconBg:
                                const Color(0xffFFF1DD),
                            iconColor:
                                const Color(0xff9A5300),
                            dotColor:
                                const Color(0xffFFA552),
                            timeColor: Colors.grey.shade500,
                          ),
                          SizedBox(height: hp(.02)),
                          AlertCard(
                            width: w,
                            title: 'Payment Confirmed...',
                            subtitle:
                                'Shopkeeper confirmed ₹20,000\nreceived from Raj',
                            time: '35 min ago',
                            icon: Icons.check_circle_outline,
                            sideColor:
                                const Color(0xff7DD7A2),
                            iconBg:
                                const Color(0xffDFF3E6),
                            iconColor:
                                const Color(0xff4D8A68),
                            dotColor:
                                const Color(0xff7DD7A2),
                            timeColor: Colors.grey.shade500,
                          ),
                          SizedBox(height: hp(.02)),
                          AlertCard(
                            width: w,
                            title: 'Raj Kumar is offline ...',
                            subtitle:
                                'Route data may be outdated',
                            time: '2 hours ago',
                            icon: Icons.sync_disabled_outlined,
                            sideColor:
                                const Color(0xffD9DED8),
                            iconBg:
                                const Color(0xffF1F2EE),
                            iconColor:
                                const Color(0xff8B909A),
                            dotColor:
                                const Color(0xffD9DED8),
                            timeColor: Colors.grey.shade500,
                          ),
                          SizedBox(height: hp(.03)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final double width;
  final String title;
  final bool active;

  const FilterChipWidget({
    super.key,
    required this.width,
    required this.title,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .05,
        vertical: width * .025,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xff0B5D38)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(width * .05),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * .045,
          fontWeight: FontWeight.w500,
          color: active
              ? Colors.white
              : const Color(0xff667085),
        ),
      ),
    );
  }
}


