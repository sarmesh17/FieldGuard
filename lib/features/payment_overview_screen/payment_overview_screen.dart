import 'package:fieldguard/features/payment_overview_screen/cheque_card.dart';
import 'package:fieldguard/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: const Color(0xffF7F7F7),
          bottomNavigationBar: BottomNavBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: hp(.03)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.06),
                      vertical: hp(.025),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Payments',
                          style: TextStyle(
                            fontSize: wp(.07),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff0B4D2B),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_month_outlined,
                          size: wp(.07),
                          color: const Color(0xff0B4D2B),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 1, color: Colors.black.withOpacity(.04)),

                  SizedBox(height: hp(.02)),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: Row(
                      children: [
                        FilterChipWidget(
                          width: w,
                          title: 'Today',
                          active: true,
                        ),
                        SizedBox(width: wp(.04)),
                        FilterChipWidget(width: w, title: 'Yesterday'),
                        SizedBox(width: wp(.04)),
                        FilterChipWidget(width: w, title: 'This Week'),
                        SizedBox(width: wp(.04)),
                        FilterChipWidget(width: w, title: 'This Month'),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.05)),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'TOTAL COLLECTED',
                          style: TextStyle(
                            fontSize: wp(.04),
                            letterSpacing: 1,
                            color: const Color(0xff667085),
                          ),
                        ),
                        SizedBox(height: hp(.015)),
                        Text(
                          '₹ 3,24,500',
                          style: TextStyle(
                            fontSize: wp(.11),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff1B6F4B),
                          ),
                        ),
                        SizedBox(height: hp(.015)),
                        Text(
                          'Cash: ₹2,10,000  ·  Cheques: ₹1,14,500',
                          style: TextStyle(
                            fontSize: wp(.048),
                            color: const Color(0xff667085),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.04)),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: WarningCard(width: w, height: h),
                  ),

                  SizedBox(height: hp(.04)),

                  SectionTitle(width: w, title: 'By Representative'),

                  SizedBox(height: hp(.02)),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: Column(
                      children: [
                        RepresentativeCard(
                          width: w,
                          initials: 'AR',
                          name: 'Anil Reddy',
                          amount: '₹52,000',
                          collections: '8 collections',
                          confirmed: '7 confirmed',
                          disputed: '1 disputed',
                          active: true,
                        ),
                        SizedBox(height: hp(.025)),
                        RepresentativeCard(
                          width: w,
                          initials: 'KS',
                          name: 'Kiran Sharma',
                          amount: '₹38,000',
                          collections: '5 collections',
                          confirmed: '5 confirmed',
                          active: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.04)),

                  SectionTitle(width: w, title: 'Cheques Collected'),

                  SizedBox(height: hp(.02)),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: Column(
                      children: [
                        ChequeCard(
                          width: w,
                          chequeNo: 'CHQ-992341',
                          amount: '₹45,000',
                          store: 'Sri Sai Traders',
                          collector: 'Collected by Anil Reddy',
                          status: 'At Office',
                          success: true,
                        ),
                        SizedBox(height: hp(.025)),
                        ChequeCard(
                          width: w,
                          chequeNo: 'CHQ-881029',
                          amount: '₹22,500',
                          store: 'Metro Supermart',
                          collector: 'Collected by Priya K',
                          status: 'Not Received',
                          success: false,
                        ),
                      ],
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
        horizontal: width * .04,
        vertical: width * .025,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xff0B5A37) : Colors.transparent,
        borderRadius: BorderRadius.circular(width * .05),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * .05,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : const Color(0xff667085),
        ),
      ),
    );
  }
}

class WarningCard extends StatelessWidget {
  final double width;
  final double height;

  const WarningCard({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * .05),
      decoration: BoxDecoration(
        color: const Color(0xffFFF3E3),
        borderRadius: BorderRadius.circular(width * .04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width * .01,
            height: height * .14,
            decoration: BoxDecoration(
              color: const Color(0xffF4A340),
              borderRadius: BorderRadius.circular(width * .02),
            ),
          ),
          SizedBox(width: width * .04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: const Color(0xffF4A340),
                      size: width * .07,
                    ),
                    SizedBox(width: width * .02),
                    Expanded(
                      child: Text(
                        '₹45,000 not yet deposited to office',
                        style: TextStyle(
                          fontSize: width * .06,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * .015),
                Text(
                  '3 reps have pending deposits',
                  style: TextStyle(
                    fontSize: width * .048,
                    color: const Color(0xff667085),
                  ),
                ),
                SizedBox(height: height * .025),
                Text(
                  'View Pending →',
                  style: TextStyle(
                    fontSize: width * .055,
                    color: const Color(0xffF4A340),
                    fontWeight: FontWeight.w600,
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

class SectionTitle extends StatelessWidget {
  final double width;
  final String title;

  const SectionTitle({super.key, required this.width, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .06),
      child: Text(
        title,
        style: TextStyle(fontSize: width * .065, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class RepresentativeCard extends StatelessWidget {
  final double width;
  final String initials;
  final String name;
  final String amount;
  final String collections;
  final String confirmed;
  final String? disputed;
  final bool active;

  const RepresentativeCard({
    super.key,
    required this.width,
    required this.initials,
    required this.name,
    required this.amount,
    required this.collections,
    required this.confirmed,
    this.disputed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * .045),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: width * .055,
                backgroundColor: active
                    ? const Color(0xffD7F0D9)
                    : const Color(0xffEFEFEF),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: width * .055,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? const Color(0xff0B4D2B)
                        : const Color(0xff667085),
                  ),
                ),
              ),
              SizedBox(width: width * .04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: width * .06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: width * .01),
                    Text(
                      collections,
                      style: TextStyle(
                        fontSize: width * .045,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: width * .06,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff1B6F4B),
                ),
              ),
            ],
          ),
          SizedBox(height: width * .05),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: width * .045,
                color: const Color(0xff35B46B),
              ),
              SizedBox(width: width * .015),
              Text(
                confirmed,
                style: TextStyle(
                  fontSize: width * .045,
                  color: const Color(0xff35B46B),
                ),
              ),
              if (disputed != null) ...[
                SizedBox(width: width * .02),
                Text(
                  '·',
                  style: TextStyle(
                    fontSize: width * .04,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(width: width * .02),
                Icon(
                  Icons.warning_amber_rounded,
                  size: width * .045,
                  color: const Color(0xffF4A340),
                ),
                SizedBox(width: width * .015),
                Text(
                  disputed!,
                  style: TextStyle(
                    fontSize: width * .03,
                    color: const Color(0xffF4A340),
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
                size: width * .06,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
