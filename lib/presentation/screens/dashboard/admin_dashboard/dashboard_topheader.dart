import 'package:flutter/material.dart';

class TopHeader extends StatelessWidget {


  final double scale;

  TopHeader({required this.scale});

  static const Color _green = Color(0xFF0E5D3B);

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: _s(22),
        vertical: _s(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _s(28),
            backgroundColor: const Color(0xFFD6F2D9),
            child: Text(
              'AS',
              style: TextStyle(
                fontSize: _s(18),
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
          SizedBox(width: _s(18)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: _green,
                  fontSize: _s(22),
                  fontWeight: FontWeight.w700,
                ),
                children: const [
                  TextSpan(text: 'Welcome back '),
                  TextSpan(text: '👋'),
                  TextSpan(text: ' Arjun Singh'),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: _s(34),
                color: const Color(0xFF78716C),
              ),
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: _s(10),
                  height: _s(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
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