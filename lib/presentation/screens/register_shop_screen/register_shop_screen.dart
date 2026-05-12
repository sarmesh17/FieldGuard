import 'package:fieldguard/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  double radius = 75;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: const Color(0xffF7F5F1),
          bottomNavigationBar: BottomNavBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: hp(.03)),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.05),
                      vertical: hp(.018),
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xffEAE6E0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: wp(.065),
                          color: const Color(0xff22523B),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Register New Shop',
                              style: TextStyle(
                                fontSize: wp(.052),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: wp(.035),
                            vertical: hp(.005),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffECE8FF),
                            borderRadius: BorderRadius.circular(wp(.03)),
                            border: Border.all(color: const Color(0xffCFC8FF)),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: wp(.026),
                              color: const Color(0xff635BFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.025)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: wp(.06)),
                    child: Row(
                      children: [
                        Expanded(
                          child: StepItem(
                            width: w,
                            number: '1',
                            title: 'SHOP INFO',
                            active: true,
                          ),
                        ),
                        Expanded(
                          child: StepItem(
                            width: w,
                            number: '2',
                            title: 'LOCATION',
                          ),
                        ),
                        Expanded(
                          child: StepItem(
                            width: w,
                            number: '3',
                            title: 'ASSIGN & TAG',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.03)),
                  SectionCard(
                    width: w,
                    accentColor: const Color(0xff1F6B46),
                    title: 'Shop Details',
                    icon: Icons.storefront_outlined,
                    child: Column(
                      children: [
                        FormFieldWidget(
                          width: w,
                          label: 'SHOP NAME',
                          hint: 'Enter business name',
                        ),
                        FormFieldWidget(
                          width: w,
                          label: 'OWNER FULL NAME',
                          hint: 'First and Last Name',
                        ),
                        FormFieldWidget(
                          width: w,
                          label: 'PHONE NUMBER',
                          hint: '+1 (555) 000-0000',
                          icon: Icons.call_outlined,
                        ),
                        FormFieldWidget(
                          width: w,
                          label: 'AREA / LOCALITY',
                          hint: 'e.g. Downtown District',
                        ),
                        FormFieldWidget(
                          width: w,
                          label: 'SHOP TYPE',
                          hint: 'Select category',
                          suffix: Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.025)),
                  SectionCard(
                    width: w,
                    title: 'Location & Geofence',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: hp(.28),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(wp(.03)),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1200&auto=format&fit=crop',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: wp(.32),
                                  height: wp(.32),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xff1F6B46),
                                      width: 3,
                                    ),
                                    color: const Color(
                                      0xff1F6B46,
                                    ).withOpacity(.12),
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  Icons.location_on,
                                  size: wp(.09),
                                  color: Colors.red,
                                ),
                              ),
                              Positioned(
                                right: wp(.04),
                                bottom: wp(.04),
                                child: Container(
                                  width: wp(.15),
                                  height: wp(.15),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.gps_fixed,
                                    color: const Color(0xff222222),
                                    size: wp(.07),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: hp(.03)),
                        Row(
                          children: [
                            Text(
                              'GEOFENCE RADIUS',
                              style: TextStyle(
                                fontSize: wp(.03),
                                letterSpacing: 1,
                                color: const Color(0xff646B7A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: wp(.03),
                                vertical: hp(.004),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffCFEFD7),
                                borderRadius: BorderRadius.circular(wp(.05)),
                              ),
                              child: Text(
                                '${radius.toInt()}m',
                                style: TextStyle(
                                  fontSize: wp(.032),
                                  color: const Color(0xff1F6B46),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: hp(.015)),
                        Row(
                          children: [
                            Text(
                              '25m',
                              style: TextStyle(
                                fontSize: wp(.032),
                                color: const Color(0xff9A948B),
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: radius,
                                min: 25,
                                max: 150,
                                activeColor: const Color(0xff1F6B46),
                                inactiveColor: const Color(0xffD8D5D0),
                                onChanged: (v) {
                                  setState(() {
                                    radius = v;
                                  });
                                },
                              ),
                            ),
                            Text(
                              '150m',
                              style: TextStyle(
                                fontSize: wp(.032),
                                color: const Color(0xff9A948B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: hp(.025)),
                  SectionCard(
                    width: w,
                    title: 'Assign & Tag',
                    icon: Icons.assignment_ind_outlined,
                    titleBadge: 'Admin Only',
                    titleBadgeColor: const Color(0xffECE8FF),
                    badgeTextColor: const Color(0xff635BFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormFieldWidget(
                          width: w,
                          label: 'ASSIGN TO REP',
                          hint: 'Select field representative',
                          icon: Icons.people_outline,
                          suffix: Icons.keyboard_arrow_down,
                        ),
                        SizedBox(height: hp(.01)),
                        Text(
                          'PRIMARY ROUTE DAY',
                          style: TextStyle(
                            fontSize: wp(.03),
                            letterSpacing: 1,
                            color: const Color(0xff646B7A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: hp(.018)),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              DayChip(width: w, text: 'Mon'),
                              DayChip(width: w, text: 'Tue'),
                              DayChip(width: w, text: 'Wed', active: true),
                              DayChip(width: w, text: 'Thu'),
                              DayChip(width: w, text: 'Fri'),
                            ],
                          ),
                        ),
                        SizedBox(height: hp(.03)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(wp(.04)),
                          decoration: BoxDecoration(
                            color: const Color(0xffF4F5F1),
                            borderRadius: BorderRadius.circular(wp(.035)),
                            border: Border.all(color: const Color(0xffE0DFDA)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.credit_card_outlined,
                                    size: wp(.06),
                                  ),
                                  SizedBox(width: wp(.03)),
                                  Text(
                                    'Physical Tagging',
                                    style: TextStyle(
                                      fontSize: wp(.05),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: hp(.025)),
                              ActionButton(
                                width: w,
                                text: 'Generate NFC ID',
                                icon: Icons.wifi_tethering,
                                outlined: true,
                                color: const Color(0xff4F46FF),
                              ),
                              SizedBox(height: hp(.015)),
                              ActionButton(
                                width: w,
                                text: 'Print QR Code',
                                icon: Icons.qr_code,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                 Padding(
  padding: EdgeInsets.symmetric(
    horizontal: wp(.06),
    vertical: hp(.025),
  ),
  child: SizedBox(
    width: double.infinity,
    height: hp(.075),
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xff1F6B46),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(wp(.035)),
        ),
        padding: EdgeInsets.symmetric(horizontal: wp(.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next',
            style: TextStyle(
              fontSize: wp(.045),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: wp(.02)),
          Icon(
            Icons.arrow_forward,
            size: wp(.05),
          ),
          SizedBox(width: wp(.02)),
          Flexible(
            child: Text(
              'Set Location',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: wp(.042),
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(.9),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StepItem extends StatelessWidget {
  final double width;
  final String number;
  final String title;
  final bool active;

  const StepItem({
    super.key,
    required this.width,
    required this.number,
    required this.title,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: const Color(0xffD9D4CD)),
            ),
            Container(
              width: width * .09,
              height: width * .09,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xff1F6B46) : Colors.white,
                border: Border.all(
                  color: active
                      ? const Color(0xff1F6B46)
                      : const Color(0xffD9D4CD),
                ),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xffA39C92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: const Color(0xffD9D4CD)),
            ),
          ],
        ),
        SizedBox(height: width * .02),
        Text(
          title,
          style: TextStyle(
            fontSize: width * .028,
            color: active ? const Color(0xff1F6B46) : const Color(0xff9A948B),
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final String? titleBadge;
  final Color? titleBadgeColor;
  final Color? badgeTextColor;

  const SectionCard({
    super.key,
    required this.width,
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor = const Color(0xffD8D5CF),
    this.titleBadge,
    this.titleBadgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * .06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .01,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * .04),
                bottomLeft: Radius.circular(width * .04),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(width * .05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: width * .06, color: accentColor),
                      SizedBox(width: width * .03),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: width * .065,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (titleBadge != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * .03,
                            vertical: width * .01,
                          ),
                          decoration: BoxDecoration(
                            color: titleBadgeColor,
                            borderRadius: BorderRadius.circular(width * .02),
                          ),
                          child: Text(
                            titleBadge!,
                            style: TextStyle(
                              fontSize: width * .028,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: width * .05),
                  Divider(height: 0, color: Colors.black.withOpacity(.08)),
                  SizedBox(height: width * .05),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FormFieldWidget extends StatelessWidget {
  final double width;
  final String label;
  final String hint;
  final IconData? icon;
  final IconData? suffix;

  const FormFieldWidget({
    super.key,
    required this.width,
    required this.label,
    required this.hint,
    this.icon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * .04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: width * .03,
              letterSpacing: 1,
              color: const Color(0xff646B7A),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: width * .025),
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * .04),
            height: width * .14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * .025),
              border: Border.all(color: const Color(0xffDDD8D1)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: width * .05, color: const Color(0xff8E8A84)),
                  SizedBox(width: width * .03),
                ],
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: width * .042,
                      color: const Color(0xffB0AAA3),
                    ),
                  ),
                ),
                if (suffix != null)
                  Icon(
                    suffix,
                    size: width * .06,
                    color: const Color(0xff7D7871),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DayChip extends StatelessWidget {
  final double width;
  final String text;
  final bool active;

  const DayChip({
    super.key,
    required this.width,
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: width * .025),
      padding: EdgeInsets.symmetric(
        horizontal: width * .045,
        vertical: width * .03,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xffCFEFD7) : Colors.transparent,
        borderRadius: BorderRadius.circular(width * .06),
        border: Border.all(
          color: active ? const Color(0xff1F6B46) : const Color(0xffDDD8D1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: width * .038,
          color: active ? const Color(0xff1F6B46) : const Color(0xff9A948B),
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final double width;
  final String text;
  final IconData icon;
  final bool outlined;
  final Color color;

  const ActionButton({
    super.key,
    required this.width,
    required this.text,
    required this.icon,
    this.outlined = false,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: width * .14,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(width * .025),
        border: Border.all(color: outlined ? color : const Color(0xffDDD8D1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: width * .055, color: color),
          SizedBox(width: width * .03),
          Text(
            text,
            style: TextStyle(
              fontSize: width * .045,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
