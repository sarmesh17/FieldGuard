/// The persisted lifecycle of the auto-geofence tracker.
///
/// `DISARMED → ARMED → INSIDE → PENDING_UPLOAD → (cleared on sync)`,
/// with the failure branch `PENDING_UPLOAD → DEAD`.
///
/// INSIDE is persisted as the open visit; PENDING_UPLOAD / DEAD are
/// persisted as retry-queue entries. ARMED / DISARMED are not persisted —
/// they are recomputed from live IN_PROGRESS task data on every launch.
enum GeofenceState {
  disarmed,
  armed,
  inside,
  pendingUpload,
  dead;

  /// Parses a persisted [name]; falls back to [pendingUpload] so an
  /// unrecognised value keeps a queued visit retryable rather than lost.
  static GeofenceState fromName(String? name) {
    return GeofenceState.values.firstWhere(
      (s) => s.name == name,
      orElse: () => GeofenceState.pendingUpload,
    );
  }
}
