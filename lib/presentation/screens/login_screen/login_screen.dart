import 'package:fieldguard/presentation/screens/login_screen/login_footer.dart';
import 'package:fieldguard/presentation/screens/login_screen/login_header.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 238, 228),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            children: [
              const Spacer(),

              /// Header Section
              Header(),

              SizedBox(height: size.height * 0.03),

              /// Role Toggle Card
              const _RoleToggleCard(),

              SizedBox(height: size.height * 0.025),

              /// Form Card
              Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label(text: "EMAIL ADDRESS"),
                    SizedBox(height: size.height * 0.01),
                    _InputField(
                      icon: Icons.mail_outline,
                      hint: "manager@fieldguard.com",
                    ),
                    SizedBox(height: size.height * 0.02),
                    const _Label(text: "PASSWORD"),
                    SizedBox(height: size.height * 0.01),
                     _PasswordField(),
                    SizedBox(height: size.height * 0.015),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: const Color(0xFF1F5A3E),
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    Container(
                      width: double.infinity,
                      height: size.height * 0.065,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5A3E),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// Footer
              Footer(),

              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleToggleCard extends StatelessWidget {
  const _RoleToggleCard();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: const [
            Expanded(child: _SelectedRole()),
            Expanded(child: _UnselectedRole()),
          ],
        ),
      ),
    );
  }
}

class _SelectedRole extends StatelessWidget {
  const _SelectedRole();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, color: Color(0xFF1F5A3E), size: 18),
          SizedBox(width: 6),
          Text(
            "Manager",
            style: TextStyle(
              color: Color(0xFF1F5A3E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnselectedRole extends StatelessWidget {
  const _UnselectedRole();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: Colors.grey, size: 18),
          SizedBox(width: 6),
          Text(
            "Admin",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Text(
      text,
      style: TextStyle(
        fontSize: size.width * 0.032,
        letterSpacing: 1,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final IconData icon;
  final String hint;

  const _InputField({required this.icon, required this.hint});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    var controller = TextEditingController();

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
          Icon(icon, color: Colors.grey.shade600),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  _PasswordField();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    var controller = TextEditingController();

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
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "••••••••",
              ),
            ),
          ),
          Icon(Icons.visibility_outlined, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
