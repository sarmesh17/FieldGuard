import 'package:flutter/material.dart';

class VisitCard extends StatelessWidget {
  final double width;
  final String title;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String duration;
  final String amount;
  final Color dotColor;
  final bool top;

  const VisitCard({
    super.key,
    required this.width,
    required this.title,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.duration,
    required this.amount,
    required this.dotColor,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -width * .13,
          top: width * .15,
          child: Container(
            width: width * .05,
            height: width * .05,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: top
                    ? const Color(0xff0B4D2B)
                    : Colors.grey.shade300,
                width: width * .01,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(width * .03),
          decoration: BoxDecoration(
            color: const Color(0xffF7F4EE),
            borderRadius: BorderRadius.circular(width * .03),
            border: Border.all(
              color: Colors.black.withOpacity(.06),
            ),
          ),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * .025,
                      vertical: width * .012,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius:
                          BorderRadius.circular(width * .05),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: width * .04,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: width * .02),
              Text(
                duration,
                style: TextStyle(
                  fontSize: width * .043,
                  color: const Color(0xff5F6678),
                ),
              ),
              if (amount.isNotEmpty) ...[
                SizedBox(height: width * .03),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .025,
                    vertical: width * .02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(width * .015),
                    border: Border.all(
                      color: Colors.black.withOpacity(.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: width * .045,
                        color: const Color(0xff0B4D2B),
                      ),
                      SizedBox(width: width * .015),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: width * .03,
                          color: const Color(0xff0B4D2B),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
