import 'package:flutter/material.dart';

class Footer extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        Text(
          "FIELDGUARD MANAGER V1.0",
          style: TextStyle(
            fontSize: size.width * 0.03,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: size.height * 0.008),
        Text(
          "Access is granted by your organization admin only",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.035,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}