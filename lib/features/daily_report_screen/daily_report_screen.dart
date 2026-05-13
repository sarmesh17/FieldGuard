import 'package:fieldguard/features/daily_report_screen/summary_card.dart';
import 'package:fieldguard/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(hp(.13)),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wp(.06),
                  vertical: hp(.015),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Report',
                            style: TextStyle(
                              fontSize: wp(.07),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0A4F31),
                            ),
                          ),
                          SizedBox(height: hp(.004)),
                          Text(
                            '3 May 2026',
                            style: TextStyle(
                              fontSize: wp(.045),
                              color: const Color(0xff767676),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.share_outlined,
                      size: wp(.07),
                      color: const Color(0xff6F625E),
                    ),
                  ],
                ),
              ),
            ),
          ),

          bottomNavigationBar: BottomNavBar(),

          body: SafeArea(
            child: Container(
              color: const Color.fromARGB(255, 223, 238, 228),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: hp(.03)),
                    Text(
                      'TEAM SUMMARY',
                      style: TextStyle(
                        fontSize: wp(.038),
                        letterSpacing: 1,
                        color: const Color(0xff62697A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: hp(.02)),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            width: w,
                            title: 'REPS ACTIVE',
                            value: '12',
                            suffix: '/ 14',
                            valueColor: const Color(0xff0A4F31),
                          ),
                        ),
                        SizedBox(width: wp(.03)),
                        Expanded(
                          child: SummaryCard(
                            width: w,
                            title: 'SHOPS COVERED',
                            value: '94',
                            suffix: '/ 142',
                            valueColor: const Color(0xff0A4F31),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hp(.02)),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            width: w,
                            title: 'TOTAL COLLECTED',
                            value: '₹ 3.2L',
                            valueColor: const Color(0xff0A4F31),
                          ),
                        ),
                        SizedBox(width: wp(.03)),
                        Expanded(
                          child: SummaryCard(
                            width: w,
                            title: 'DISPUTES RAISED',
                            value: '3',
                            valueColor: const Color(0xffFF2433),
                            sideColor: const Color(0xffFF2433),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hp(.035)),
                    SectionCard(
                      width: w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shop Coverage',
                            style: TextStyle(
                              fontSize: wp(.065),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: hp(.03)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              minHeight: hp(.012),
                              value: .66,
                              backgroundColor: const Color(0xffEFEDE7),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xff0A5A36),
                              ),
                            ),
                          ),
                          SizedBox(height: hp(.018)),
                          Row(
                            children: [
                              Text(
                                '94 visited',
                                style: TextStyle(
                                  fontSize: wp(.045),
                                  color: const Color(0xff0A4F31),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '48 not covered',
                                style: TextStyle(
                                  fontSize: wp(.045),
                                  color: const Color(0xff667085),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: hp(.025)),
                          Divider(
                            color: Colors.black.withOpacity(.08),
                            height: 0,
                          ),
                          SizedBox(height: hp(.025)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Uncovered Shops (48)',
                                  style: TextStyle(
                                    fontSize: wp(.052),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: wp(.065),
                                color: const Color(0xff667085),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: hp(.035)),
                    SectionCard(
                      width: w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rep Performance',
                            style: TextStyle(
                              fontSize: wp(.065),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: hp(.03)),
                          Row(
                            children: [
                              tableHeader(w, 'REP', flex: 3),
                              tableHeader(w, 'SHOPS', flex: 2),
                              tableHeader(w, 'COLLECTED', flex: 3),
                              tableHeader(w, 'FLAGS', flex: 2),
                            ],
                          ),
                          SizedBox(height: hp(.015)),
                          Divider(
                            color: Colors.black.withOpacity(.08),
                            height: 0,
                          ),
                          PerformanceRow(
                            width: w,
                            name: 'Vikram S.',
                            shops: '8/8',
                            collected: '₹52,000',
                            flags: '0',
                          ),
                          PerformanceRow(
                            width: w,
                            name: 'Anil K.',
                            shops: '5/8',
                            collected: '₹31,000',
                            flags: '2 ⚠',
                            warning: true,
                          ),
                          PerformanceRow(
                            width: w,
                            name: 'Rahul M.',
                            shops: '10/10',
                            collected: '₹85,500',
                            flags: '0',
                          ),
                          PerformanceRow(
                            width: w,
                            name: 'Pooja D.',
                            shops: '7/7',
                            collected: '₹41,000',
                            flags: '0',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: hp(.035)),
                    SectionCard(
                      width: w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Collections",
                            style: TextStyle(
                              fontSize: wp(.065),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: hp(.03)),
                          CollectionRow(
                            width: w,
                            title: 'Total Cash',
                            value: '₹2,10,000',
                          ),
                          CollectionRow(
                            width: w,
                            title: 'Total Cheques',
                            value: '₹1,14,500',
                          ),
                          CollectionRow(
                            width: w,
                            title: 'Disputed',
                            value: '₹5,000',
                            valueColor: Colors.red,
                            titleColor: Colors.red,
                          ),
                          CollectionRow(
                            width: w,
                            title: 'Confirmed',
                            value: '₹3,19,500',
                            valueColor: const Color(0xff0A4F31),
                            titleColor: const Color(0xff0A4F31),
                          ),
                          CollectionRow(
                            width: w,
                            title: 'Pending confirmation',
                            value: '₹5,000',
                            valueColor: const Color(0xffFF944D),
                            titleColor: const Color(0xffFF944D),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: hp(.06)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          color: const Color(0xff0A4F31),
                          size: wp(.06),
                        ),
                        SizedBox(width: wp(.03)),
                        Text(
                          'Export Full Report',
                          style: TextStyle(
                            fontSize: wp(.055),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff0A4F31),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hp(.08)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget tableHeader(double w, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: w * .036,
          letterSpacing: 1,
          color: const Color(0xff62697A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final double width;
  final Widget child;

  const SectionCard({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * .055),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PerformanceRow extends StatelessWidget {
  final double width;
  final String name;
  final String shops;
  final String collected;
  final String flags;
  final bool warning;

  const PerformanceRow({
    super.key,
    required this.width,
    required this.name,
    required this.shops,
    required this.collected,
    required this.flags,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: width * .04),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(name, style: TextStyle(fontSize: width * .045)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                shops,
                style: TextStyle(
                  fontSize: width * .045,
                  color: warning
                      ? const Color(0xffFF944D)
                      : const Color(0xff0A4F31),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(collected, style: TextStyle(fontSize: width * .045)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                flags,
                style: TextStyle(
                  fontSize: width * .045,
                  color: warning ? Colors.red : const Color(0xff0A4F31),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: width * .04),
        Divider(color: Colors.black.withOpacity(.08), height: 0),
      ],
    );
  }
}

class CollectionRow extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final Color? valueColor;
  final Color? titleColor;
  final bool showDivider;

  const CollectionRow({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    this.valueColor,
    this.titleColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: width * .05,
                  color: titleColor ?? const Color(0xff667085),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: width * .05,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: width * .04),
          Divider(color: Colors.black.withOpacity(.08), height: 0),
          SizedBox(height: width * .04),
        ],
      ],
    );
  }
}
