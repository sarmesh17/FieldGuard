import 'package:flutter/material.dart';

class Header extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          height: size.width * 0.18,
          width: size.width * 0.18,
          decoration: BoxDecoration(
            color: const Color(0xFF2F6F4E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: const Icon(Icons.shield_outlined,
              color: Colors.white, size: 34),
        ),
        SizedBox(height: size.height * 0.02),
        Text(
          "Manager Portal",
          style: TextStyle(
            fontSize: size.width * 0.075,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          "Secure corporate access to team monitoring",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.04,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}