import 'package:flutter/material.dart';

class ChequeCard extends StatelessWidget {
  final double width;
  final String chequeNo;
  final String amount;
  final String store;
  final String collector;
  final String status;
  final bool success;

  const ChequeCard({
    super.key,
    required this.width,
    required this.chequeNo,
    required this.amount,
    required this.store,
    required this.collector,
    required this.status,
    required this.success,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chequeNo,
                  style: TextStyle(
                    fontSize: width * .04,
                    letterSpacing: 1,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: width * .07,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: width * .025),
          Text(
            store,
            style: TextStyle(
              fontSize: width * .06,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: width * .015),
          Text(
            collector,
            style: TextStyle(
              fontSize: width * .048,
              color: const Color(0xff667085),
            ),
          ),
          SizedBox(height: width * .03),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * .03,
              vertical: width * .012,
            ),
            decoration: BoxDecoration(
              color: success
                  ? const Color(0xffD7F0D9)
                  : const Color(0xffFFF1DD),
              borderRadius:
                  BorderRadius.circular(width * .05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success
                      ? Icons.check
                      : Icons.warning_amber_rounded,
                  size: width * .04,
                  color: success
                      ? const Color(0xff1B6F4B)
                      : const Color(0xffF4A340),
                ),
                SizedBox(width: width * .01),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: width * .042,
                    color: success
                        ? const Color(0xff1B6F4B)
                        : const Color(0xffF4A340),
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
