import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/presentation/notifiers/login_notifier.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_notifier.dart';
import 'package:fieldguard/presentation/screens/signup_screen/uploadDocs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final passwardController = TextEditingController();
  final phoneNoController = TextEditingController();
  final panCardController = TextEditingController();
  final companyNameController = TextEditingController();
  final adminNameController = TextEditingController();

  @override
  void dispose() {
    passwardController.dispose();
    phoneNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupNotifierProvider);

    final notifier = ref.read(signupNotifierProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 223, 238, 228),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, innerConstraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: innerConstraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),

                          /// ================= HEADER =================
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: SizeConfig.scale(40),
                                    width: SizeConfig.scale(40),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF165C3D),
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.scale(8),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: SizeConfig.scale(30),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.heightPercent(1.5)),
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(26),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: SizeConfig.heightPercent(1)),
                              Text(
                                "Secure access to your agent portal",
                                style: TextStyle(
                                  fontSize: SizeConfig.scaledFontSize(14),
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.heightPercent(1.5)),

                          /// ================= FORM CARD =================
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth:
                                  SizeConfig.screenType == ScreenType.large
                                  ? 500
                                  : double.infinity,
                            ),
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(
                                SizeConfig.scale(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// EMAIL
                                _label("Company Name"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                _InputField(
                                  controller: companyNameController,
                                  icon: Icons.corporate_fare_outlined,
                                  hint: "xyz Pvt.Ltd.",
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// AUTHORITY
                                _label("Pan Card Number"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                _InputField(
                                  controller: panCardController,
                                  icon: Icons.contact_page_outlined,
                                  hint: "ABCDE 1234 N",
                                  buttonText: 'verify',
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// AUTHORITY
                                _label("Adim Name"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                _InputField(
                                  controller: adminNameController,
                                  icon: Icons.shield_outlined,
                                  hint: "John Doe",
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// PHONE
                                _label("Mobile Number"),
                                SizedBox(height: SizeConfig.heightPercent(1)),

                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.scale(6),
                                        horizontal: SizeConfig.scale(7),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          SizeConfig.scale(14),
                                        ),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          value: signupState.selectedKey,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          onChanged: (value) {
                                            if (value != null) {
                                              notifier.setSelectedCountry(
                                                value,
                                              );
                                            }
                                          },
                                          items: notifier.images.entries.map((
                                            entry,
                                          ) {
                                            return DropdownMenuItem(
                                              value: entry.key,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundImage:
                                                        NetworkImage(
                                                          entry.value,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(entry.key),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: SizeConfig.scale(10)),

                                    Expanded(
                                      child: SizedBox(
                                        height: SizeConfig.scale(55),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              SizeConfig.scale(14),
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            expands: true,
                                            maxLines: null,
                                            controller: phoneNoController,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor: Colors.white,
                                              hintText: "0000000000",
                                              hintStyle: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize:
                                                    SizeConfig.scaledFontSize(
                                                      14,
                                                    ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade400,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade400,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade400,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// PASSWORD
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _label("Password"),
                                    Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: const Color(0xFF165C3D),
                                        fontSize: SizeConfig.scaledFontSize(13),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: SizeConfig.heightPercent(1)),

                                SignupPasswordField(
                                  controller: passwardController,
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),
                                _label('CitizenShip Proof'),
                                SizedBox(height: SizeConfig.heightPercent(1)),
                                UploaddocsScreen(),

                                SizedBox(height: SizeConfig.heightPercent(2)),
                                _label('Registration Document'),
                                SizedBox(height: SizeConfig.heightPercent(1)),
                                UploaddocsScreen(),

                                SizedBox(height: SizeConfig.heightPercent(3)),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 4,
                                      backgroundColor: const Color(0xFF165C3D),
                                      padding: EdgeInsets.symmetric(
                                        vertical: SizeConfig.scale(16),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          SizeConfig.scale(14),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.go('/login');
                                    },
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(16),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: SizeConfig.heightPercent(2)),

                                /// FOOTER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: SizeConfig.scale(16),
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: SizeConfig.scale(6)),
                                    Text(
                                      "SECURE END-TO-END ENCRYPTION",
                                      style: TextStyle(
                                        fontSize: SizeConfig.scaledFontSize(8),
                                        letterSpacing: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          SizedBox(height: SizeConfig.heightPercent(2)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: SizeConfig.scaledFontSize(12),
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class SignupPasswordField extends ConsumerWidget {
  final TextEditingController controller;

  SignupPasswordField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidePassword = ref.watch(
      signupNotifierProvider.select((s) => s.hidePassword),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: SizeConfig.scale(20),
          ),
          SizedBox(width: SizeConfig.scale(12)),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: hidePassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "••••••••",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: SizeConfig.scaledFontSize(14),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(14),
                ),
              ),
              style: TextStyle(fontSize: SizeConfig.scaledFontSize(14)),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(signupNotifierProvider.notifier)
                .togglePasswordVisibility(),
            icon: Icon(
              hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: SizeConfig.scale(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends ConsumerWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final String? buttonText;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupState = ref.watch(signupNotifierProvider);

    final notifier = ref.read(signupNotifierProvider.notifier);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: SizeConfig.scale(20)),

          SizedBox(width: SizeConfig.scale(12)),

          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                suffixIcon: buttonText != 'verify'
                    ? null
                    : signupState.isVerifying
                    ? Padding(
                        padding: EdgeInsets.all(SizeConfig.scale(12)),
                        child: SizedBox(
                          height: SizeConfig.scale(18),
                          width: SizeConfig.scale(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : TextButton(
                        style: ButtonStyle(
                          splashFactory: NoSplash.splashFactory,
                        ),

                        onPressed: () {
                          notifier.setVerificationLoading(true);
                        },

                        child: Text(
                          buttonText!,
                          style: TextStyle(
                            color: const Color(0xFF165C3D),
                            fontSize: SizeConfig.scale(12),
                          ),
                        ),
                      ),

                border: InputBorder.none,

                hintText: hint,

                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: SizeConfig.scaledFontSize(14),
                ),

                contentPadding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(14),
                ),
              ),

              style: TextStyle(fontSize: SizeConfig.scaledFontSize(14)),
            ),
          ),
        ],
      ),
    );
  }
}
