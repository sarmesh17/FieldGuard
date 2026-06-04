import 'package:fieldguard/features/fraud_alert_screen/resolve_card.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class FraudAlertsScreen extends StatelessWidget {
  const FraudAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wp(.05),
                    vertical: hp(.018),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: wp(.07),
                        color: Colors.black87,
                      ),
                      const Spacer(),
                      Text(
                        'Fraud Alerts',
                        style: TextStyle(
                          fontSize: wp(.055),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: wp(.04),
                          vertical: hp(.008),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red8,
                          borderRadius: BorderRadius.circular(wp(.08)),
                        ),
                        child: Text(
                          '3 Unresolved',
                          style: TextStyle(
                            color: AppColors.red4,
                            fontSize: wp(.038),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.black.withOpacity(.05)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wp(.06),
                    vertical: hp(.018),
                  ),
                  child: Row(
                    children: [
                      TopTab(text: 'All', selected: true, width: w),
                      SizedBox(width: wp(.06)),
                      TopTab(text: 'Payment', width: w),
                      SizedBox(width: wp(.06)),
                      TopTab(text: 'Visit', width: w),
                      SizedBox(width: wp(.06)),
                      TopTab(text: 'Pattern', width: w),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: wp(.04)),
                    children: [
                      SummarySection(width: w),
                      SizedBox(height: hp(.02)),
                      AlertCard(
                        width: w,
                        height: h,
                        level: 'High',
                        levelColor: AppColors.red4,
                        borderColor: AppColors.red4,
                        title: 'Payment Amount Disputed',
                        person: 'Raj Kumar',
                        shop: 'Mehta Traders',
                        message:
                            'System recorded ₹5,000\ncollection, but shopkeeper SMS\nreply confirms only ₹3,000 paid.',
                        action1: 'SMS Reply',
                        action2: 'GPS Verified',
                        isHigh: true,
                      ),
                      SizedBox(height: hp(.02)),
                      AlertCard(
                        width: w,
                        height: h,
                        level: 'Med',
                        levelColor: AppColors.brown5,
                        borderColor: AppColors.orange4,
                        title: 'Visit Duration Too Short',
                        person: 'Amit Singh',
                        shop: 'Sharma Kirana',
                        message:
                            'Reported full stock check, but GPS\nduration within geofence was only 1\nmin 12 sec.',
                        action1: 'Geofence Log',
                        action2: 'GPS Photo',
                        isHigh: false,
                      ),
                      SizedBox(height: hp(.02)),
                      ResolvedCard(width: w, height: h),
                      SizedBox(height: hp(.03)),
                    ],
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

class TopTab extends StatelessWidget {
  final String text;
  final bool selected;
  final double width;

  const TopTab({
    super.key,
    required this.text,
    required this.width,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.green : AppColors.grey5,
            fontSize: width * .042,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(height: width * .02),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: selected ? width * .11 : 0,
          height: width * .008,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(width * .02),
          ),
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  final double width;

  const SummarySection({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: width * .043,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * .02),
      child: Row(
        children: [
          Text(
            '3 High\nRisk',
            style: textStyle.copyWith(color: AppColors.red4),
          ),
          SizedBox(width: width * .04),
          Text(
            '·',
            style: TextStyle(
              fontSize: width * .07,
              color: AppColors.grey18,
            ),
          ),
          SizedBox(width: width * .04),
          Text(
            '5\nMedium',
            style: textStyle.copyWith(color: AppColors.orange4),
          ),
          SizedBox(width: width * .04),
          Text(
            '·',
            style: TextStyle(
              fontSize: width * .07,
              color: AppColors.grey18,
            ),
          ),
          SizedBox(width: width * .04),
          Text(
            '2 Resolved\nToday',
            style: textStyle.copyWith(color: AppColors.grey5),
          ),
        ],
      ),
    );
  }
}

class ActionChipWidget extends StatelessWidget {
  final double width;
  final double height;
  final String text;
  final IconData icon;

  const ActionChipWidget({
    super.key,
    required this.width,
    required this.height,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .04,
        vertical: height * .012,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(width * .06),
        border: Border.all(color: AppColors.grey32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: width * .045, color: AppColors.grey16),
          SizedBox(width: width * .015),
          Text(
            text,
            style: TextStyle(
              fontSize: width * .04,
              color: AppColors.grey16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ResolvedCard extends StatelessWidget {
  final double width;
  final double height;

  const ResolvedCard({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .45,
      child: Container(
        padding: EdgeInsets.all(width * .045),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * .06),
          border: Border.all(color: AppColors.grey34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fake GPS Location Detected',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontSize: width * .045,
                      color: Colors.black.withOpacity(.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: width * .07,
                  height: width * .07,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gradientEnd,
                      width: width * .004,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: width * .045,
                    color: AppColors.gradientEnd,
                  ),
                ),
              ],
            ),
            SizedBox(height: height * .02),
            Row(
              children: [
                Icon(Icons.person_outline, size: width * .045),
                SizedBox(width: width * .015),
                Text(
                  'Vikram Das',
                  style: TextStyle(
                    fontSize: width * .042,
                    color: Colors.black.withOpacity(.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * .022),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .035,
                    vertical: height * .012,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(width * .025),
                  ),
                  child: Text(
                    'Resolved by you',
                    style: TextStyle(fontSize: width * .038),
                  ),
                ),
                SizedBox(width: width * .03),
                Text(
                  '·  2 hours ago',
                  style: TextStyle(
                    fontSize: width * .04,
                    color: Colors.black.withOpacity(.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
