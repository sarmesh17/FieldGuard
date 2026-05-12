import 'package:fieldguard/presentation/screens/visit_history_screen/visit_card.dart';
import 'package:fieldguard/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class VisitHistoryScreen extends StatelessWidget {
  const VisitHistoryScreen({super.key});

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
                  SizedBox(height: hp(.015)),
                  Row(
                    children: [
                      Container(
                        width: wp(.11),
                        height: wp(.11),
                        decoration: BoxDecoration(
                          color: const Color(0xffECEBE6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(.05),
                          ),
                        ),
                        child: Icon(
                          Icons.account_circle_outlined,
                          size: wp(.07),
                          color: const Color(0xff6C736B),
                        ),
                      ),
                      SizedBox(width: wp(.04)),
                      Expanded(
                        child: Text(
                          'Visit History',
                          style: TextStyle(
                            fontSize: wp(.09),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff0A4F31),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.filter_alt_outlined,
                        size: wp(.075),
                        color: const Color(0xff0A4F31),
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.035)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChipWidget(
                          width: w,
                          title: 'Today',
                          active: true,
                        ),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(width: w, title: 'This Week'),
                        SizedBox(width: wp(.03)),
                        FilterChipWidget(width: w, title: 'This Month'),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.03)),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownBox(width: w, title: 'All Reps'),
                      ),
                      SizedBox(width: wp(.04)),
                      Expanded(
                        child: DropdownBox(width: w, title: 'All Shops'),
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.03)),
                  Text(
                    'Showing 142 visits · 3 May 2026',
                    style: TextStyle(
                      fontSize: wp(.04),
                      color: const Color(0xff9A958F),
                    ),
                  ),
                  SizedBox(height: hp(.03)),
                  Row(
                    children: [
                      Text(
                        'TODAY — 3 MAY 2026',
                        style: TextStyle(
                          fontSize: wp(.037),
                          letterSpacing: 1,
                          color: const Color(0xff62697A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '38 visits',
                        style: TextStyle(
                          fontSize: wp(.04),
                          color: const Color(0xff62697A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: hp(.015)),
                  Divider(color: Colors.black.withOpacity(.08), height: 0),
                  SizedBox(height: hp(.02)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          VisitCard(
                            width: w,
                            sideColor: const Color(0xff57C88A),
                            shop: 'Sharma Store',
                            rep: 'Raj Kumar',
                            time: '2:34 PM',
                            duration: '18 min',
                            status: 'Confirmed ✓',
                            amount: '₹8,000',
                            tag: 'NFC ✓',
                            tagColor: const Color(0xffCDEFD4),
                            tagTextColor: const Color(0xff0A4F31),
                            statusColor: const Color(0xff0A4F31),
                            expanded: false,
                          ),
                          SizedBox(height: hp(.02)),
                          VisitCard(
                            width: w,
                            sideColor: const Color(0xffFFA552),
                            shop: 'Gupta Electronics',
                            rep: 'Amit Singh',
                            time: '1:15 PM',
                            duration: '42 min',
                            status: 'No Reply',
                            amount: '',
                            tag: 'NFC ✓',
                            tagColor: const Color(0xffCDEFD4),
                            tagTextColor: const Color(0xff0A4F31),
                            statusColor: const Color(0xffA49D97),
                            expanded: false,
                          ),
                          SizedBox(height: hp(.02)),
                          VisitCard(
                            width: w,
                            sideColor: const Color(0xffFF2B45),
                            shop: 'Metro Supermarket',
                            rep: 'Raj Kumar',
                            time: '11:05 AM',
                            duration: '5 min',
                            status: 'Disputed ⚠',
                            amount: '',
                            tag: 'Manual Entry',
                            tagColor: const Color(0xffFFE1E1),
                            tagTextColor: const Color(0xffC70000),
                            statusColor: const Color(0xffC70000),
                            expanded: true,
                          ),
                          SizedBox(height: hp(.05)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_outlined,
                                color: const Color(0xff0A4F31),
                                size: wp(.065),
                              ),
                              SizedBox(width: wp(.03)),
                              Text(
                                'Export as PDF / CSV',
                                style: TextStyle(
                                  fontSize: wp(.055),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff0A4F31),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: hp(.06)),
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
        horizontal: width * .03,
        vertical: width * .03,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xff0A5A36) : Colors.white,
        borderRadius: BorderRadius.circular(width * .05),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * .042,
          color: active ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class DropdownBox extends StatelessWidget {
  final double width;
  final String title;

  const DropdownBox({super.key, required this.width, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .05,
        vertical: width * .045,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .03),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: width * .045)),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: width * .06,
            color: const Color(0xff737A73),
          ),
        ],
      ),
    );
  }
}

class AuditItem extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String time;
  final bool danger;

  const AuditItem({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.time,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * .05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: width * .01,
                height: width * .01,
                decoration: BoxDecoration(
                  color: danger ? Colors.red : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: width * .13,
                color: Colors.black.withOpacity(.08),
              ),
            ],
          ),
          SizedBox(width: width * .04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: width * .048,
                          color: danger ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: width * .04,
                        color: const Color(0xff8F8A84),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: width * .01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: width * .038,
                      color: const Color(0xff5B6475),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final double width;
  final IconData icon;
  final String text;
  final Color bg;
  final Color textColor;

  const InfoChip({
    super.key,
    required this.width,
    required this.icon,
    required this.text,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .025,
        vertical: width * .015,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(width * .02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: width * .04, color: textColor),
          SizedBox(width: width * .015),
          Text(
            text,
            style: TextStyle(
              fontSize: width * .04,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
