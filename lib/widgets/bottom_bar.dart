import 'package:flutter/material.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

// ─── Brand palette (consistent with the rest of the app) ────────────────────
const _kPrimary = AppColors.green;
const _kPillBg = AppColors.green6;
const _kInactive = AppColors.grey8;

/// Modern bottom navigation bar (Material-3 style).
///
/// A clean white bar with rounded top corners and a soft lift shadow. Each tab
/// is an equal-width column — an animated green "active indicator" pill sits
/// behind the selected icon, with the label below. Equal [Expanded] slots mean
/// it can never overflow regardless of label length or text scale.
///
/// Keeps the same `currentIndex` / `onTap` interface as the old
/// [BottomNavigationBar] so the router shell needs no changes.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({super.key, this.currentIndex = 0, this.onTap});

  static const _items = <_NavItemData>[
    _NavItemData('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _NavItemData('Shops', Icons.store_outlined, Icons.store),
    _NavItemData('Routes', Icons.route_outlined, Icons.route),
    _NavItemData('Team', Icons.people_outline, Icons.people),
    _NavItemData('Profile', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap?.call(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItemData(this.label, this.icon, this.activeIcon);
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _kPrimary : _kInactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated "active indicator" pill behind the icon.
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 32,
            width: 56,
            decoration: BoxDecoration(
              color: selected ? _kPillBg : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              selected ? data.activeIcon : data.icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
