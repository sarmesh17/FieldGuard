import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "FIELDGUARD MANAGER V1.0",
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(8),
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: SizeConfig.scale(4)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            "Access is granted by your organization admin only",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(10),
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
