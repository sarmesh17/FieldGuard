import 'package:fieldguard/features/manager_panel/add_rep_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

class ManageRepsScreen extends StatelessWidget {
  const ManageRepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: wp(.06),
                        vertical: hp(.02),
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.orange),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: wp(.085),
                            color: AppColors.grey23,
                          ),
                          SizedBox(width: wp(.04)),
                          Expanded(
                            child: Text(
                              'Manage Reps',
                              style: TextStyle(
                                fontSize: wp(.08),
                                fontWeight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: wp(.08),
                                color: AppColors.green,
                              ),
                              SizedBox(width: wp(.015)),
                              Text(
                                'Add Rep',
                                style: TextStyle(
                                  fontSize: wp(.055),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: wp(.06),
                          vertical: hp(.025),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: wp(.05),
                              ),
                              height: hp(.085),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(wp(.04)),
                                border: Border.all(
                                  color: AppColors.grey32,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: wp(.085),
                                    color: AppColors.grey5,
                                  ),
                                  SizedBox(width: wp(.03)),
                                  Expanded(
                                    child: Text(
                                      'Search reps by name, phone, or zone',
                                      style: TextStyle(
                                        fontSize: wp(.05),
                                        color: AppColors.grey5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: hp(.025)),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChipWidget(
                                    width: w,
                                    title: 'All',
                                    active: true,
                                    activeColor: AppColors.blue10,
                                  ),
                                  FilterChipWidget(width: w, title: 'Active'),
                                  FilterChipWidget(width: w, title: 'Inactive'),
                                  FilterChipWidget(
                                    width: w,
                                    title: 'Flagged',
                                    outlinedRed: true,
                                    icon: Icons.outlined_flag,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: hp(.03)),
                            RepCard(width: w),
                            SizedBox(height: hp(.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AddRepBottomSheet(width: w, height: h),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final double width;
  final String title;
  final bool active;
  final bool outlinedRed;
  final IconData? icon;
  final Color activeColor;

  const FilterChipWidget({
    super.key,
    required this.width,
    required this.title,
    this.active = false,
    this.outlinedRed = false,
    this.icon,
    this.activeColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: width * .03),
      padding: EdgeInsets.symmetric(
        horizontal: width * .055,
        vertical: width * .03,
      ),
      decoration: BoxDecoration(
        color: active
            ? activeColor
            : outlinedRed
            ? AppColors.white10
            : Colors.white,
        borderRadius: BorderRadius.circular(width * .08),
        border: Border.all(
          color: outlinedRed
              ? AppColors.red17
              : AppColors.grey14,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: width * .045,
              color: outlinedRed ? AppColors.red11 : Colors.white,
            ),
            SizedBox(width: width * .015),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: width * .05,
              fontWeight: FontWeight.w500,
              color: active
                  ? Colors.white
                  : outlinedRed
                  ? AppColors.red11
                  : AppColors.grey21,
            ),
          ),
        ],
      ),
    );
  }
}

class RepCard extends StatelessWidget {
  final double width;

  const RepCard({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .012,
            decoration: BoxDecoration(
              color: AppColors.blue11,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * .05),
                bottomLeft: Radius.circular(width * .05),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width * .05),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: width * .16,
                            height: width * .16,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: width * .05,
                              height: width * .05,
                              decoration: BoxDecoration(
                                color: AppColors.green5,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: width * .04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rajesh Thapa',
                              style: TextStyle(
                                fontSize: width * .07,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: width * .01),
                            Text(
                              'Kat...  ·  Joined Oct \'23',
                              style: TextStyle(
                                fontSize: width * .045,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: .9,
                        child: Switch(
                          value: true,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.green,
                          onChanged: (_) {},
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up,
                        size: width * .07,
                        color: AppColors.grey28,
                      ),
                    ],
                  ),
                  SizedBox(height: width * .05),
                  Divider(color: Colors.black.withOpacity(.06), height: 0),
                  SizedBox(height: width * .04),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONTACT',
                              style: TextStyle(
                                fontSize: width * .04,
                                letterSpacing: 1,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: width * .02),
                            Text(
                              '+977 984-1234567',
                              style: TextStyle(
                                fontSize: width * .055,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASSIGNMENT',
                              style: TextStyle(
                                fontSize: width * .04,
                                letterSpacing: 1,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: width * .02),
                            Text(
                              '47 shops',
                              style: TextStyle(
                                fontSize: width * .055,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class InputLabel extends StatelessWidget {
  final String title;

  const InputLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        letterSpacing: 1,
        color: AppColors.grey19,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final double width;
  final String hint;
  final IconData? suffix;

  const InputField({
    super.key,
    required this.width,
    required this.hint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: width * .16,
      padding: EdgeInsets.symmetric(horizontal: width * .04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .03),
        border: Border.all(color: AppColors.grey14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: width * .05,
                color: AppColors.grey5,
              ),
            ),
          ),
          if (suffix != null)
            Icon(suffix, size: width * .06, color: AppColors.grey5),
        ],
      ),
    );
  }
}
