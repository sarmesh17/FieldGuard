import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color sideColor;
  final Color iconBg;
  final Color iconColor;
  final Color dotColor;
  final Color timeColor;
  final bool showAction;
  final String? actionText;

  const AlertCard({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.sideColor,
    required this.iconBg,
    required this.iconColor,
    required this.dotColor,
    required this.timeColor,
    this.showAction = false,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .012,
            height: width * .34,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: BorderRadius.only(
                topLeft:
                    Radius.circular(width * .04),
                bottomLeft:
                    Radius.circular(width * .04),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(width * .05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight:
                      Radius.circular(width * .04),
                  bottomRight:
                      Radius.circular(width * .04),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: width * .03,
                        height: width * .03,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: width * .03),
                      Container(
                        width: width * .11,
                        height: width * .11,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: width * .065,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: width * .045),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      width * .055,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                                width: width * .02),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize:
                                    width * .042,
                                color: timeColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: width * .025),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: width * .048,
                            height: 1.4,
                            color:
                                const Color(0xff667085),
                          ),
                        ),
                        if (showAction) ...[
                          SizedBox(
                              height: width * .035),
                          Text(
                            actionText ?? '',
                            style: TextStyle(
                              fontSize:
                                  width * .048,
                              color:
                                  const Color(
                                      0xffFF334B),
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
