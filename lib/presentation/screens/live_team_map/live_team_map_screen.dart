import 'package:fieldguard/presentation/screens/live_team_map/live_team_map_card.dart';
import 'package:fieldguard/presentation/screens/live_team_map/live_team_map_header.dart';
import 'package:flutter/material.dart';


class LiveTeamMapScreen extends StatelessWidget {
  const LiveTeamMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width > 700;
        final horizontalPadding = isTablet ? 28.0 : 18.0;

        return Scaffold(
          backgroundColor: const Color(0xffF7F5F2),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 18,
                  ),
                  child: const HeaderSection(),
                ),
                const Divider(height: 1),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: const _UpdateSection(),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            flex: 9,
                            child: Stack(
                              children: [
                                const _MapSection(),

                                Positioned(
                                  top: 18,
                                  left: horizontalPadding,
                                  right: horizontalPadding,
                                  child: const _MapLegend(),
                                ),

                                const Positioned(
                                  top: 165,
                                  left: 250,
                                  child: _MapMarker(
                                    initials: "RK",
                                    bgColor: Color(0xff005B33),
                                    borderColor: Color(0xff005B33),
                                    textColor: Colors.white,
                                  ),
                                ),

                                const Positioned(
                                  top: 240,
                                  right: 110,
                                  child: _MapMarker(
                                    initials: "SM",
                                    bgColor: Color(0xffF7A35C),
                                    borderColor: Color(0xffF7A35C),
                                    textColor: Color(0xff6D3200),
                                  ),
                                ),

                                Positioned(
                                  bottom: 35,
                                  right: horizontalPadding,
                                  child: const _FitAllButton(),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 10,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xffF7F5F2),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(34),
                                  topRight: Radius.circular(34),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),

                                  Container(
                                    width: 90,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),

                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                      vertical: 22,
                                    ),
                                    child: const _RepresentativeHeader(),
                                  ),

                                  const Divider(height: 1),

                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding,
                                        vertical: 16,
                                      ),
                                      children: const [
                                        RepresentativeCard(
                                          initials: 'RK',
                                          name: 'Ryan King',
                                          status: 'In Shop: Target\nNorth',
                                          shopsDone: '5',
                                          totalShops: '8',
                                          accentColor: Color(0xff005B33),
                                          avatarColor: Color(0xffD8F1DE),
                                          textColor: Color(0xff005B33),
                                          dotColor: Color(0xff0B7A43),
                                        ),
                                        SizedBox(height: 16),
                                        RepresentativeCard(
                                          initials: 'SM',
                                          name: 'Sarah Miller',
                                          status: 'Traveling to CVS',
                                          shopsDone: '3',
                                          totalShops: '6',
                                          accentColor: Color(0xffF7A35C),
                                          avatarColor: Color(0xffFFE1CC),
                                          textColor: Color(0xff7A3A00),
                                          dotColor: Color(0xffF7A35C),
                                        ),
                                        SizedBox(height: 16),
                                        RepresentativeCard(
                                          initials: 'JD',
                                          name: 'John Doe',
                                          status: 'Inactive',
                                          shopsDone: '0',
                                          totalShops: '4',
                                          accentColor: Color(0xffD8DDD8),
                                          avatarColor: Color(0xffEEEEEE),
                                          textColor: Color(0xff9EA3AD),
                                          dotColor: Color(0xffD8DDD8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
        );
      },
    );
  }
}


class _UpdateSection extends StatelessWidget {
  const _UpdateSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: Colors.grey.shade500,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Updated 30 sec ago',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        const Icon(
          Icons.refresh,
          color: Color(0xff005B33),
          size: 34,
        ),
      ],
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.network(
        'https://preview.redd.it/apple-maps-has-the-best-quality-satellite-images-and-3d-view-v0-alwg1cf8rwwb1.png?auto=webp&s=f4169568990e73132b8d18e767c32aecda4223ba',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/8/88/Openstreetmap_demo.png',
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(
            color: Color(0xff005B33),
            title: 'In Shop',
          ),
          _LegendItem(
            color: Color(0xffF7A35C),
            title: 'Traveling',
          ),
          _LegendItem(
            color: Color(0xffB9C2B9),
            title: 'Inactive',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const _LegendItem({
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: color,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String initials;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _MapMarker({
    required this.initials,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 5,
        ),
        color: Colors.white,
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FitAllButton extends StatelessWidget {
  const _FitAllButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.fit_screen_outlined),
          SizedBox(width: 12),
          Text(
            'Fit All',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepresentativeHeader extends StatelessWidget {
  const _RepresentativeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'All Representatives',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffF4F1EC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xffE1DDD6),
            ),
          ),
          child: const Text(
            '12 Total',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xff687184),
            ),
          ),
        ),
      ],
    );
  }
}

