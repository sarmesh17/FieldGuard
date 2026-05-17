import 'package:flutter/material.dart';

class ManagerHeaderSection extends StatelessWidget {
  const ManagerHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff163B45),
            border: Border.all(color: const Color(0xff163B45)),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 38),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Morning, 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff005C33),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Arjun Singh",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff005C33),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffEAE6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(
                  color: Color(0xff5B57FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.notifications_none_outlined,
            size: 30,
            color: Color(0xff005C33),
          ),
        ),
      ],
    );
  }
}