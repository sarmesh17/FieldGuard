import 'package:fieldguard/features/manager_panel/manager_panel.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class AddRepBottomSheet extends StatelessWidget {
  final double width;
  final double height;

  const AddRepBottomSheet({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * .63,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(width * .06)),
      ),
      child: Column(
        children: [
          SizedBox(height: width * .03),
          Container(
            width: width * .12,
            height: width * .015,
            decoration: BoxDecoration(
              color: AppColors.grey30,
              borderRadius: BorderRadius.circular(width),
            ),
          ),
          SizedBox(height: width * .05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .06),
            child: Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.blue5,
                  size: width * .08,
                ),
                SizedBox(width: width * .03),
                Expanded(
                  child: Text(
                    'Add New Rep',
                    style: TextStyle(
                      fontSize: width * .085,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: width * .12,
                  height: width * .12,
                  decoration: const BoxDecoration(
                    color: AppColors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: width * .08,
                    color: AppColors.grey22,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: width * .05),
          Divider(color: Colors.black.withOpacity(.08), height: 0),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(width * .06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputLabel(title: 'FULL NAME'),
                  SizedBox(height: width * .03),
                  InputField(width: width, hint: 'e.g. Ram Shrestha'),
                  SizedBox(height: width * .05),
                  const InputLabel(title: 'PHONE NUMBER'),
                  SizedBox(height: width * .03),
                  Row(
                    children: [
                      Container(
                        width: width * .22,
                        height: width * .16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * .03),
                          border: Border.all(color: AppColors.grey14),
                        ),
                        child: Center(
                          child: Text(
                            '+977',
                            style: TextStyle(
                              fontSize: width * .06,
                              color: AppColors.grey20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: width * .04),
                      Expanded(
                        child: InputField(width: width, hint: '98XXXXXXXX'),
                      ),
                    ],
                  ),
                  SizedBox(height: width * .05),
                  const InputLabel(title: 'EMAIL ADDRESS (OPTIONAL)'),
                  SizedBox(height: width * .03),
                  InputField(width: width, hint: 'ram@fieldops.com'),
                  SizedBox(height: width * .05),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(title: 'ASSIGNED ZONE'),
                            SizedBox(height: width * .03),
                            InputField(
                              width: width,
                              hint: 'Select Zone',
                              suffix: Icons.keyboard_double_arrow_down,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: width * .04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(title: 'DIRECT MANAGER'),
                            SizedBox(height: width * .03),
                            InputField(
                              width: width,
                              hint: 'Select Manager',
                              suffix: Icons.keyboard_double_arrow_down,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: width * .08),
                  SizedBox(
                    width: double.infinity,
                    height: width * .16,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green13,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * .03),
                        ),
                      ),
                      child: Text(
                        'Send Invite & Create Account',
                        style: TextStyle(
                          fontSize: width * .06,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
