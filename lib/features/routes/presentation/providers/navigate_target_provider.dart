import 'package:flutter_riverpod/legacy.dart';

/// A shop the user asked to navigate to, set by the task-detail "Navigate"
/// action and consumed by the Routes screen to auto-draw the route.
///
/// Carries only what the route needs — the destination coordinates and a
/// label — so it stays decoupled from the task/shop DTOs. `null` means no
/// pending navigation (Routes shows its default state).
class NavigateTarget {
  final int taskId;
  final double lat;
  final double lng;
  final String shopName;
  final String? address;

  const NavigateTarget({
    required this.taskId,
    required this.lat,
    required this.lng,
    required this.shopName,
    this.address,
  });
}

/// Set by the Navigate button before switching to the Routes tab; the Routes
/// screen reads it once to select the destination, then clears it so a later
/// manual tab visit doesn't redraw a stale route.
final navigateTargetProvider = StateProvider<NavigateTarget?>((ref) => null);
