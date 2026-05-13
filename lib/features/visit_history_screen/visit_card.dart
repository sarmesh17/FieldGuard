import 'package:fieldguard/features/visit_history_screen/visit_history_screen.dart';
import 'package:flutter/material.dart';

class VisitCard extends StatelessWidget {
  final double width;
  final Color sideColor;
  final String shop;
  final String rep;
  final String time;
  final String duration;
  final String status;
  final String amount;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final Color statusColor;
  final bool expanded;

  const VisitCard({
    super.key,
    required this.width,
    required this.sideColor,
    required this.shop,
    required this.rep,
    required this.time,
    required this.duration,
    required this.status,
    required this.amount,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    required this.statusColor,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .012,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * .04),
                bottomLeft: Radius.circular(width * .04),
              ),
            ),
            height: expanded ? width * .95 : width * .44,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(width * .05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(width * .04),
                  bottomRight: Radius.circular(width * .04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop,
                          style: TextStyle(
                            fontSize: width * .06,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: width * .045,
                          color: const Color(0xffA49D97),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: width * .01),
                  Text(
                    rep,
                    style: TextStyle(
                      fontSize: width * .045,
                      color: const Color(0xff667085),
                    ),
                  ),
                  SizedBox(height: width * .04),
                  Wrap(
                    spacing: width * .02,
                    runSpacing: width * .02,
                    children: [
                      InfoChip(
                        width: width,
                        icon: Icons.access_time,
                        text: duration,
                        bg: const Color(0xffF1F3EF),
                        textColor: const Color(0xff5B6475),
                      ),
                      InfoChip(
                        width: width,
                        icon: Icons.qr_code_2,
                        text: tag,
                        bg: tagColor,
                        textColor: tagTextColor,
                      ),
                      if (amount.isNotEmpty)
                        InfoChip(
                          width: width,
                          icon: Icons.account_balance_wallet_outlined,
                          text: amount,
                          bg: const Color(0xffF6F4F1),
                          textColor: const Color(0xff000000),
                        ),
                    ],
                  ),
                  SizedBox(height: width * .05),
                  Divider(color: Colors.black.withOpacity(.08), height: 0),
                  SizedBox(height: width * .04),
                  Row(
                    children: [
                      Icon(
                        expanded
                            ? Icons.warning_amber_outlined
                            : status == 'No Reply'
                            ? Icons.remove_circle_outline
                            : Icons.verified_outlined,
                        color: statusColor,
                        size: width * .05,
                      ),
                      SizedBox(width: width * .02),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: width * .045,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xff0A4F31),
                        size: width * .07,
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    SizedBox(height: width * .06),
                    Divider(color: Colors.black.withOpacity(.08), height: 0),
                    SizedBox(height: width * .05),
                    Text(
                      'AUDIT TRAIL',
                      style: TextStyle(
                        fontSize: width * .038,
                        letterSpacing: 1,
                        color: const Color(0xff62697A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: width * .05),
                    AuditItem(
                      width: width,
                      title: 'Manual Entry Logged',
                      subtitle: 'Location spoofing suspected',
                      time: '11:05 AM',
                    ),
                    AuditItem(
                      width: width,
                      title: 'Order Placed',
                      subtitle: '',
                      time: '11:08 AM',
                    ),
                    AuditItem(
                      width: width,
                      title: 'Shopkeeper Dispute Logged',
                      subtitle: '"Rep never arrived, order placed remotely"',
                      time: '11:10 AM',
                      danger: true,
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
}
