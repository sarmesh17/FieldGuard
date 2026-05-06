import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = SizeConfig.scale(68);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: logoSize,
          width: logoSize,
          decoration: BoxDecoration(
            color: const Color(0xFF2F6F4E),
            borderRadius: BorderRadius.circular(SizeConfig.scale(20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x26000000),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: logoSize * 0.5,
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(2)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Manager Portal",
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(28),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            "Secure corporate access to team monitoring",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(14),
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
