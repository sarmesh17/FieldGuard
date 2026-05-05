import 'package:fieldguard/presentation/screens/login_screen/login_provider.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupPasswardfield extends StatelessWidget {
  final TextEditingController controller;

  SignupPasswardfield({required this.controller});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final provider = context.watch<SignupProvider>();

    return Container(
      height: size.height * 0.065,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.black),
              controller: controller,
              obscureText: provider.hidePassward,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "••••••••",
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              provider.showPassward();
            },
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
            icon: provider.hidePassward == true
                ? Icon(
                    Icons.visibility_off_outlined,
                    color: Colors.grey.shade600,
                  )
                : Icon(Icons.visibility_outlined, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
