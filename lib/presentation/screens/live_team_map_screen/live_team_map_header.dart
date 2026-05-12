import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.arrow_back,
          size: 34,
          color: Colors.black,
        ),
        const SizedBox(width: 20),
        const Expanded(
          child: Text(
            'Live Team Map',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffD4F0D7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xffB6DDBA),
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xff7ACB92),
              ),
              SizedBox(width: 12),
              Text(
                '12 Active',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff005B33),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
