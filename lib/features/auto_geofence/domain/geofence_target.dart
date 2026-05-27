/// A shop geofence armed from an IN_PROGRESS task.
///
/// Built only when the task carries a shop with parseable, in-range
/// coordinates — tasks with missing or invalid shop coordinates are
/// skipped and never produce a target.
class GeofenceTarget {
  final int taskId;
  final int shopId;
  final String shopName;

  /// Geofence centre — the shop's coordinates.
  final double latitude;
  final double longitude;

  const GeofenceTarget({
    required this.taskId,
    required this.shopId,
    required this.shopName,
    required this.latitude,
    required this.longitude,
  });
}
