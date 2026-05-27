/// Tunable constants for the automatic geofence visit tracker.
///
/// Kept in one place so the detection geometry, retry policy and polling
/// cadence can be reviewed and adjusted without touching service logic.
class GeofenceConfig {
  const GeofenceConfig._();

  // ── Detection geometry ─────────────────────────────────────────────
  /// Distance (m) at or under which an ARMED target counts as entered.
  static const double enterRadiusMeters = 20;

  /// Distance (m) at or beyond which an INSIDE visit starts accruing
  /// exit evidence. The gap to [enterRadiusMeters] is the hysteresis
  /// band — fixes inside it change nothing, which is what stops boundary
  /// jitter from spamming enter/exit transitions.
  static const double exitRadiusMeters = 28;

  /// Fixes with an accuracy radius worse (larger) than this are dropped:
  /// a noisy fix is neither enter nor exit evidence.
  static const double maxAccuracyMeters = 35;

  /// A fix implying travel faster than this since the previous good fix
  /// is treated as a GPS teleport glitch and discarded.
  static const double maxPlausibleSpeedMps = 85; // ~306 km/h

  // ── Exit confirmation ──────────────────────────────────────────────
  /// An exit is confirmed once this many consecutive outside fixes are
  /// seen, OR [exitSustainedDuration] of continuous outside time has
  /// elapsed — whichever first. One stray fix never closes a visit.
  static const int exitConsecutiveFixes = 3;
  static const Duration exitSustainedDuration = Duration(seconds: 30);

  // ── Visit validity ─────────────────────────────────────────────────
  /// A confirmed visit shorter than this is treated as boundary jitter
  /// and discarded without producing a record.
  static const Duration minValidStay = Duration(seconds: 45);

  /// While INSIDE, if no fresh in-geofence fix has arrived for this long
  /// the tracker actively probes the GPS; if location is unavailable the
  /// visit is closed from the last in-geofence fix (estimated exit).
  static const Duration staleVisitTimeout = Duration(minutes: 6);

  // ── Task polling (safety-net only) ─────────────────────────────────
  /// Reactive task changes are the primary arm/disarm trigger; this poll
  /// is the backstop for changes made on another device / by the server.
  static const Duration taskPollInterval = Duration(minutes: 3);
  static const int taskFetchLimit = 100;

  // ── Upload retry ───────────────────────────────────────────────────
  /// Attempts before a queued visit is marked DEAD (permanent failure).
  static const int maxUploadAttempts = 8;

  /// Backoff: base * 2^(attempt-1), capped at [retryMaxDelay].
  static const Duration retryBaseDelay = Duration(seconds: 5);
  static const Duration retryMaxDelay = Duration(minutes: 30);
}
