import 'package:fieldguard/presentation/screens/admin_panel/admin_panel.dart';
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final double width;
  final double height;

  const StatusCard({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * .045),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .012,
            height: height * .26,
            decoration: BoxDecoration(
              color: const Color(0xff5B4CFF),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          SizedBox(width: width * .04),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'SYSTEM STATUS',
                  style: TextStyle(
                    fontSize: width * .03,
                    letterSpacing: 1.5,
                    color: const Color(0xff5B4CFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: height * .02),
                const StatusRow(
                  title: 'Total Reps',
                  value: '24 active / 2 inactive',
                ),
                const Divider(),
                const StatusRow(
                  title: 'Total Shops',
                  value: '186 registered',
                ),
                const Divider(),
                const StatusRow(
                  title: 'NFC Tags',
                  value: '142 deployed / 44 pending',
                ),
                SizedBox(height: height * .02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .04,
                    vertical: height * .015,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffEFF8F1),
                    borderRadius:
                        BorderRadius.circular(width * .03),
                    border: Border.all(
                      color: const Color(0xffCBE8D1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xff31A363),
                        size: width * .04,
                      ),
                      SizedBox(width: width * .025),
                      Text(
                        'All systems operational',
                        style: TextStyle(
                          fontSize: width * .032,
                          color: const Color(0xff31A363),
                        ),
                      ),
                    ],
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