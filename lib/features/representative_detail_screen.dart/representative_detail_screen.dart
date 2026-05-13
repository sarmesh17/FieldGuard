import 'package:fieldguard/features/representative_detail_screen.dart/rep_visit_card_details.dart';
import 'package:flutter/material.dart';

class RepDetailsScreen extends StatelessWidget {
  const RepDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: Color.fromARGB(255, 223, 238, 228),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: hp(.04)),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.06),
                      vertical: hp(.018),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F5F2),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(.08),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: wp(.07),
                          color: const Color(0xff0B4D2B),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Raj Kumar',
                              style: TextStyle(
                                fontSize: wp(.06),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff0B4D2B),
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.call_outlined,
                          size: wp(.065),
                          color: const Color(0xff0B4D2B),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.03)),

                  CircleAvatar(
                    radius: wp(.09),
                    backgroundColor: const Color(0xffD5EFD7),
                    child: Text(
                      'RK',
                      style: TextStyle(
                        fontSize: wp(.05),
                        color: const Color(0xff103D23),
                      ),
                    ),
                  ),

                  SizedBox(height: hp(.018)),

                  Text(
                    'Raj Kumar',
                    style: TextStyle(
                      fontSize: wp(.055),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: hp(.012)),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.04),
                      vertical: hp(.008),
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 200, 231, 210),
                      borderRadius: BorderRadius.circular(wp(.06)),
                    ),
                    child: Text(
                      'Sales Representative',
                      style: TextStyle(
                        fontSize: wp(.045),
                        color: const Color(0xff1A5B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: hp(.02)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: wp(.045),
                        color: Colors.grey,
                      ),
                      SizedBox(width: wp(.01)),
                      Text(
                        'Kathmandu Zone',
                        style: TextStyle(
                          fontSize: wp(.045),
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp(.018)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: wp(.02),
                        height: wp(.02),
                        decoration: const BoxDecoration(
                          color: Color(0xff42B36A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: wp(.02)),
                      Text(
                        'Currently Active · In Field since 8:30 AM',
                        style: TextStyle(
                          fontSize: wp(.035),
                          color: const Color(0xff5F6678),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp(.03)),

                  SectionCard(
                    width: w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: "Today's Performance", width: w),
                        SizedBox(height: hp(.025)),
                        const PerformanceRow(
                          title: 'Shops Assigned',
                          value: '8',
                        ),
                        const Divider(),
                        const PerformanceRow(
                          title: 'Shops Visited',
                          value: '5',
                          valueColor: Color(0xff0B4D2B),
                        ),
                        const Divider(),
                        const PerformanceRow(
                          title: 'Remaining',
                          value: '3',
                          valueColor: Color(0xffF4A340),
                        ),
                        const Divider(),
                        const PerformanceRow(
                          title: 'Total Collected',
                          value: '₹ 28,000',
                          valueColor: Color(0xff0B4D2B),
                          bold: true,
                        ),
                        SizedBox(height: hp(.025)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: wp(.04),
                            vertical: hp(.018),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(wp(.03)),
                            border: Border.all(
                              color: Colors.black.withOpacity(.08),
                            ),
                            color: const Color(0xffFBF8F3),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Fraud alerts this week',
                                  style: TextStyle(
                                    fontSize: wp(.045),
                                    color: const Color(0xff5F6678),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: wp(.03),
                                  vertical: hp(.006),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFFE7E7),
                                  borderRadius: BorderRadius.circular(wp(.05)),
                                ),
                                child: Text(
                                  '2 flags',
                                  style: TextStyle(
                                    fontSize: wp(.042),
                                    color: const Color(0xffF04444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.03)),

                  SectionCard(
                    width: w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: "Today's Visit Log", width: w),
                        SizedBox(height: hp(.03)),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              SizedBox(
                                width: wp(.18),
                                child: Column(
                                  children: [
                                    Text(
                                      '10:30\nAM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: wp(.045),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: hp(.07)),
                                    Text(
                                      '09:15\nAM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: wp(.045),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: wp(.05),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 1.5,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    VisitCard(
                                      width: w,
                                      title: 'Sharma General',
                                      status: 'NFC',
                                      statusBg: const Color(0xffD9F0D9),
                                      statusColor: const Color(0xff1C5D37),
                                      duration: '18 min duration',
                                      amount: '₹8,000 · Confirmed',
                                      dotColor: const Color(0xff0B4D2B),
                                      top: true,
                                    ),
                                    SizedBox(height: hp(.03)),
                                    VisitCard(
                                      width: w,
                                      title: 'Laxmi Stores',
                                      status: 'QR⚠',
                                      statusBg: const Color(0xffFFF0DA),
                                      statusColor: const Color(0xffF4A340),
                                      duration: '12 min duration',
                                      amount: '',
                                      dotColor: Colors.grey.shade300,
                                      top: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.03)),

                  SectionCard(
                    width: w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: 'Payments This Week', width: w),
                        SizedBox(height: hp(.03)),
                        PaymentTile(
                          width: w,
                          title: 'Sharma General',
                          amount: '₹8,000',
                          subtitle: 'Today',
                        ),
                        Divider(color: Colors.black.withOpacity(.08)),
                        PaymentTile(
                          width: w,
                          title: 'Gupta Traders',
                          amount: '₹15,000',
                          subtitle: 'Yesterday',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: hp(.05)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: wp(.05),
                        color: const Color(0xff0B4D2B),
                      ),
                      SizedBox(width: wp(.025)),
                      Text(
                        'Message Rep',
                        style: TextStyle(
                          fontSize: wp(.05),
                          color: const Color(0xff0B4D2B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: hp(.05)),

                  Text(
                    'View Full History',
                    style: TextStyle(
                      fontSize: wp(.05),
                      color: const Color(0xff5F6678),
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

class SectionCard extends StatelessWidget {
  final Widget child;
  final double width;

  const SectionCard({super.key, required this.child, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width * .88,
      padding: EdgeInsets.all(width * .055),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFA),
        borderRadius: BorderRadius.circular(width * .05),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final double width;

  const SectionTitle({super.key, required this.title, required this.width});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: width * .055, fontWeight: FontWeight.w500),
    );
  }
}

class PerformanceRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool bold;

  const PerformanceRow({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * .025),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: w * .047,
                color: const Color(0xff5F6678),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: w * .05,
              color: valueColor ?? Colors.black,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  final double width;
  final String title;
  final String amount;
  final String subtitle;

  const PaymentTile({
    super.key,
    required this.width,
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * .02),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: width * .05,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: width * .01),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: width * .045,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: width * .055,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: width * .015),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * .03,
                  vertical: width * .012,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffD9F0D9),
                  borderRadius: BorderRadius.circular(width * .05),
                ),
                child: Text(
                  'Settled',
                  style: TextStyle(
                    fontSize: width * .04,
                    color: const Color(0xff1A5B35),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
