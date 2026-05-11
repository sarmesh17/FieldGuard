import 'package:flutter/material.dart';


class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar();

  static const Color _green = Color(0xFF0E5D3B);
  static const Color _inactive = Color(0xFFACA49F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'HOME',
                active: true,
                activeColor: _green,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                label: 'TEAM',
                active: false,
                activeColor: _green,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.warning_amber_outlined,
                label: 'ALERTS',
                active: false,
                activeColor: _green,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.payments_outlined,
                label: 'PAYMENTS',
                active: false,
                activeColor: _green,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFILE',
                active: false,
                activeColor: _green,
                inactiveColor: _inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}