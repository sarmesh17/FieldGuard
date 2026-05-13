import 'package:fieldguard/features/fraud_alert_screen/fraud_alert_screen.dart';
import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final double width;
  final double height;
  final String level;
  final Color levelColor;
  final Color borderColor;
  final String title;
  final String person;
  final String shop;
  final String message;
  final String action1;
  final String action2;
  final bool isHigh;

  const AlertCard({
    super.key,
    required this.width,
    required this.height,
    required this.level,
    required this.levelColor,
    required this.borderColor,
    required this.title,
    required this.person,
    required this.shop,
    required this.message,
    required this.action1,
    required this.action2,
    required this.isHigh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .06),
      ),
      child: Row(
        children: [
          Container(
            width: width * .01,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * .06),
                bottomLeft: Radius.circular(width * .06),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width * .045),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: width * .05,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * .035,
                          vertical: height * .008,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(.08),
                          borderRadius: BorderRadius.circular(width * .06),
                          border: Border.all(
                            color: levelColor.withOpacity(.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHigh
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline,
                              size: width * .04,
                              color: levelColor,
                            ),
                            SizedBox(width: width * .01),
                            Text(
                              level,
                              style: TextStyle(
                                color: levelColor,
                                fontSize: width * .04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .015),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: width * .045,
                        color: const Color(0xff7A8190),
                      ),
                      SizedBox(width: width * .01),
                      Text(
                        person,
                        style: TextStyle(
                          fontSize: width * .042,
                          color: const Color(0xff667085),
                        ),
                      ),
                      SizedBox(width: width * .025),
                      Icon(
                        Icons.arrow_forward,
                        size: width * .045,
                        color: const Color(0xff98A2B3),
                      ),
                      SizedBox(width: width * .025),
                      Icon(
                        Icons.storefront_outlined,
                        size: width * .045,
                        color: const Color(0xff7A8190),
                      ),
                      SizedBox(width: width * .01),
                      Expanded(
                        child: Text(
                          shop,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * .042,
                            color: const Color(0xff667085),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .02),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(width * .04),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(.06),
                      borderRadius: BorderRadius.circular(width * .04),
                      border: Border.all(color: borderColor.withOpacity(.12)),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: width * .043,
                        height: 1.5,
                        color: const Color(0xff2D2D2D),
                      ),
                    ),
                  ),
                  SizedBox(height: height * .02),
                  Wrap(
                    spacing: width * .03,
                    runSpacing: height * .012,
                    children: [
                      ActionChipWidget(
                        width: width,
                        height: height,
                        text: action1,
                        icon: isHigh ? Icons.sms_outlined : Icons.gps_fixed,
                      ),
                      ActionChipWidget(
                        width: width,
                        height: height,
                        text: action2,
                        icon: isHigh
                            ? Icons.gps_fixed
                            : Icons.camera_alt_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: height * .03),
                  if (isHigh) ...[
                    contactRow(width, 'Shopkeeper'),
                    SizedBox(height: height * .015),
                    contactRow(width, 'Rep'),
                    SizedBox(height: height * .025),
                    SizedBox(
                      width: double.infinity,
                      height: height * .055,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff045C38),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * .025),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Resolve',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * .045,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        'Warn Rep',
                        style: TextStyle(
                          color: const Color(0xffA4510B),
                          fontSize: width * .048,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: height * .025),
                    Center(
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: const Color(0xff2D2D2D),
                          fontSize: width * .046,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget contactRow(double width, String text) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.call_outlined,
            size: width * .05,
            color: const Color(0xff2D2D2D),
          ),
          SizedBox(width: width * .02),
          Text(text, style: TextStyle(fontSize: width * .045)),
        ],
      ),
    );
  }
}
