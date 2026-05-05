import 'package:fieldguard/presentation/screens/signup_screen/signup_passwardfield.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_provider.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/presentation/screens/signup_screen/signup_textfield.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});
  final passwardController = TextEditingController();
  final phoneNoController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<SignupProvider>();

    // 🔥 Scaling factors
    final scaleW = size.width / 375; // base width
    final scaleH = size.height / 812; // base height

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 243, 239),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scaleW,
              vertical: 5 * scaleH,
            ),
            child: Column(
              children: [
                SizedBox(height: 15 * scaleH),

                /// Logo + Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 30 * scaleW,
                      width: 30 * scaleW,
                      decoration: BoxDecoration(
                        color: const Color(0xFF165C3D),
                        borderRadius: BorderRadius.circular(8 * scaleW),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10 * scaleW,
                            offset: Offset(0, 4 * scaleH),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 18 * scaleW,
                      ),
                    ),
                    SizedBox(width: 12 * scaleW),
                    Text(
                      "FieldGuard",
                      style: TextStyle(
                        fontSize: 18 * scaleW,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF165C3D),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15 * scaleH),

                /// Welcome Text
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28 * scaleW,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5 * scaleH),

                Text(
                  "Secure access to your agent portal",
                  style: TextStyle(fontSize: 14 * scaleW, color: Colors.grey),
                ),

                SizedBox(height: 30 * scaleH),

                /// Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18 * scaleW),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scaleW),
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
                      /// Mobile Number

                      /// Email
                      Text(
                        "Email Address",
                        style: TextStyle(
                          fontSize: 16 * scaleW,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10 * scaleH),

                      CustomTextField(
                        hint: "manager@fieldguard.com",
                        icon: Icons.mail_outline,
                      ),

                      SizedBox(height: 20 * scaleH),

                      Text(
                        "Authority",
                        style: TextStyle(
                          fontSize: 16 * scaleW,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10 * scaleH),
                      Container(
                        height: size.height * 0.065,
                        alignment: Alignment.center,
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
                        child: DropdownButtonFormField<String>(
                          value: provider.selectedRole, // default value
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items: ["Admin", "Manager"].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundImage: NetworkImage(
                                      "https://tse4.mm.bing.net/th/id/OIP.hwUr71-kfQM8x3tR-AIoGQHaIr?w=860&h=1008&rs=1&pid=ImgDetMain&o=7&rm=3",
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(role),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.setRole(value);
                            }
                          },
                        ),
                      ),

                      SizedBox(height: 20 * scaleH),
                      Text(
                        "Mobile Number",
                        style: TextStyle(
                          fontSize: 16 * scaleW,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10 * scaleH),

                      Container(
                        decoration: BoxDecoration(),

                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  borderRadius: BorderRadius.circular(15),
                                  value: provider
                                      .selectedKey, // 👈 add this in provider
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (value) {
                                    if (value != null) {
                                      provider.setSelectedCountry(value);
                                    }
                                  },
                                  items: provider.images1.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundImage: NetworkImage(
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

                            const SizedBox(width: 10),

                            /// Phone Field
                            Expanded(
                              child: SizedBox(
                                height: 70,
                                child: TextField(
                                  controller: phoneNoController,
                                  expands: true,
                                  maxLines: null,
                                  minLines: null,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: "0000000000",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20 * scaleH),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 16 * scaleW,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: const Color(0xFF165C3D),
                              fontSize: 13 * scaleW,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10 * scaleH),

                      SignupPasswardfield(controller: passwardController),
                      SizedBox(height: 30 * scaleH),

                      /// Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52 * scaleH,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF165C3D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14 * scaleW),
                            ),
                            elevation: 8,
                          ),
                          onPressed: () {},
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16 * scaleW,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      /// Request Access
                      SizedBox(height: 20 * scaleH),

                      /// Encryption Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16 * scaleW,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 6 * scaleW),
                          Text(
                            "SECURE END-TO-END ENCRYPTION",
                            style: TextStyle(
                              fontSize: 11 * scaleW,
                              letterSpacing: 1,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
