import 'package:flutter/material.dart';

class RepresentativeCard extends StatelessWidget {
  final String initials;
  final String name;
  final String status;
  final String shopsDone;
  final String totalShops;
  final Color accentColor;
  final Color avatarColor;
  final Color textColor;
  final Color dotColor;

  const RepresentativeCard({
    required this.initials,
    required this.name,
    required this.status,
    required this.shopsDone,
    required this.totalShops,
    required this.accentColor,
    required this.avatarColor,
    required this.textColor,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xffE3DED7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 170,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 22),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: dotColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.4,
                                  color: Color(0xff687184),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Shops\nDone',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: Color(0xffAAA39B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: shopsDone,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: ' / $totalShops',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xffAAA39B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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