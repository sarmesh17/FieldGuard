import 'package:fieldguard/features/shop_management_screen/shop_card.dart';
import 'package:flutter/material.dart';

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double wp(double v) => w * v;
        double hp(double v) => h * v;

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 223, 238, 228),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wp(.06),
                    vertical: hp(.018),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: wp(.045),
                        backgroundImage: NetworkImage(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRcSnARIyTpxrNLmt0beqyWDKAgUnWMsG5j1A&s',
                        ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      SizedBox(width: wp(.03)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shops',
                              style: TextStyle(
                                fontSize: wp(.06),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff0B4D2B),
                              ),
                            ),
                            SizedBox(height: hp(.002)),
                            Text(
                              '186 Total',
                              style: TextStyle(
                                fontSize: wp(.032),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.search,
                        size: wp(.055),
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: wp(.05)),
                      Icon(
                        Icons.tune,
                        size: wp(.055),
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.black.withOpacity(.04)),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wp(.06),
                      vertical: hp(.02),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: wp(.04),
                            vertical: hp(.002),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(wp(.025)),
                            border: Border.all(
                              color: Colors.black.withOpacity(.06),
                            ),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search,
                                color: Colors.grey.shade500,
                                size: wp(.05),
                              ),
                              hintText: 'Search shop name or area...',
                              hintStyle: TextStyle(
                                fontSize: wp(.037),
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: hp(.02)),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChipWidget(
                                width: w,
                                title: 'All',
                                active: true,
                              ),
                              SizedBox(width: wp(.025)),
                              FilterChipWidget(
                                width: w,
                                title: 'Visited Today',
                              ),
                              SizedBox(width: wp(.025)),
                              FilterChipWidget(width: w, title: 'Not Visited'),
                              SizedBox(width: wp(.025)),
                              FilterChipWidget(width: w, title: 'High Balance'),
                            ],
                          ),
                        ),

                        SizedBox(height: hp(.03)),

                        ShopCard(
                          width: w,
                          title: 'Sharma Ele...',
                          owner: 'Owner: Sharma Ji',
                          address: 'Thamel, Kat...',
                          amount: '₹12,500',
                          status: 'Visited ✓',
                          amountColor: const Color(0xffFF3B30),
                          statusColor: const Color(0xff1A8F4C),
                          statusBg: const Color(0xffDDF3E3),
                          sideColor: const Color(0xff33C481),
                        ),

                        SizedBox(height: hp(.022)),

                        ShopCard(
                          width: w,
                          title: 'Lalitpur Kirana',
                          owner: 'Owner: Ramesh\nShrestha',
                          address: 'Patan Durbar S...',
                          amount: '₹0',
                          status: 'Not Yet',
                          amountColor: const Color(0xff0B4D2B),
                          statusColor: Colors.grey.shade600,
                          statusBg: const Color(0xffF1F1F1),
                          sideColor: Colors.transparent,
                        ),

                        SizedBox(height: hp(.022)),

                        ShopCard(
                          width: w,
                          title: 'Himalayan...',
                          owner: 'Owner: Tenzing\nSherpa',
                          address: 'Boudhanath...',
                          amount: '₹45,200',
                          status: 'Flagged ⚑',
                          amountColor: const Color(0xffFF3B30),
                          statusColor: const Color(0xff5B5CFF),
                          statusBg: const Color(0xffECEBFF),
                          sideColor: const Color(0xff5B5CFF),
                        ),
                      ],
                    ),
                  ),
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

  const FilterChipWidget({
    super.key,
    required this.width,
    required this.title,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * .04,
        vertical: width * .018,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xff0B5A37) : Colors.white,
        borderRadius: BorderRadius.circular(width * .05),
        border: Border.all(
          color: active
              ? const Color(0xff0B5A37)
              : Colors.black.withOpacity(.06),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * .033,
          fontWeight: FontWeight.w500,
          color: active ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }
}
