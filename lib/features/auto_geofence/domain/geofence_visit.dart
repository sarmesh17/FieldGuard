import 'package:fieldguard/features/auto_geofence/domain/geofence_state.dart';

/// A completed geofence visit — the exact `POST /api/v1/geofence-visits`
/// request body.
///
/// `stayDurationSeconds` is derived from the persisted UTC timestamps and
/// clamped to `>= 0` (a clock adjustment can otherwise yield a negative).
/// The same JSON shape is used for local persistence and for the API.
class GeofenceVisit {
  final String visitId;
  final int taskId;
  final int? shopId;
  final DateTime enteredAtUtc;
  final DateTime exitedAtUtc;

  /// True when the exit was not observed as a clean geofence crossing —
  /// recovered after interruption, or forced by the task ending.
  final bool exitEstimated;

  final double enterLatitude;
  final double enterLongitude;
  final double exitLatitude;
  final double exitLongitude;

  const GeofenceVisit({
    required this.visitId,
    required this.taskId,
    required this.shopId,
    required this.enteredAtUtc,
    required this.exitedAtUtc,
    required this.exitEstimated,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.exitLatitude,
    required this.exitLongitude,
  });

  int get stayDurationSeconds {
    final seconds = exitedAtUtc.difference(enteredAtUtc).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  /// Request body for `POST /api/v1/geofence-visits`; also the local
  /// persistence form (round-trips via [fromJson]).
  Map<String, dynamic> toJson() => {
    'visitId': visitId,
    'taskId': taskId,
    'shopId': shopId,
    'enteredAt': enteredAtUtc.toUtc().toIso8601String(),
    'exitedAt': exitedAtUtc.toUtc().toIso8601String(),
    'stayDurationSeconds': stayDurationSeconds,
    'exitEstimated': exitEstimated,
    'enterLatitude': enterLatitude,
    'enterLongitude': enterLongitude,
    'exitLatitude': exitLatitude,
    'exitLongitude': exitLongitude,
  };

  factory GeofenceVisit.fromJson(Map<String, dynamic> json) => GeofenceVisit(
    visitId: json['visitId'] as String,
    taskId: (json['taskId'] as num).toInt(),
    shopId: (json['shopId'] as num?)?.toInt(),
    enteredAtUtc: DateTime.parse(json['enteredAt'] as String).toUtc(),
    exitedAtUtc: DateTime.parse(json['exitedAt'] as String).toUtc(),
    exitEstimated: json['exitEstimated'] as bool? ?? false,
    enterLatitude: (json['enterLatitude'] as num).toDouble(),
    enterLongitude: (json['enterLongitude'] as num).toDouble(),
    exitLatitude: (json['exitLatitude'] as num).toDouble(),
    exitLongitude: (json['exitLongitude'] as num).toDouble(),
  );
}

/// A completed visit waiting in the persisted retry queue, with the
/// metadata that drives exponential backoff.
class QueuedVisit {
  final GeofenceVisit visit;

  /// Number of upload attempts already made.
  final int attemptCount;

  /// Earliest UTC time the next attempt may run (backoff gate).
  final DateTime nextAttemptAtUtc;

  /// `pendingUpload` while retryable; `dead` once attempts are exhausted.
  final GeofenceState state;

  const QueuedVisit({
    required this.visit,
    required this.attemptCount,
    required this.nextAttemptAtUtc,
    required this.state,
  });

  bool get isDead => state == GeofenceState.dead;

  QueuedVisit copyWith({
    int? attemptCount,
    DateTime? nextAttemptAtUtc,
    GeofenceState? state,
  }) {
    return QueuedVisit(
      visit: visit,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAtUtc: nextAttemptAtUtc ?? this.nextAttemptAtUtc,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
    'visit': visit.toJson(),
    'attemptCount': attemptCount,
    'nextAttemptAtUtc': nextAttemptAtUtc.toUtc().toIso8601String(),
    'state': state.name,
  };

  factory QueuedVisit.fromJson(Map<String, dynamic> json) => QueuedVisit(
    visit: GeofenceVisit.fromJson(json['visit'] as Map<String, dynamic>),
    attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
    nextAttemptAtUtc: DateTime.parse(
      json['nextAttemptAtUtc'] as String,
    ).toUtc(),
    state: GeofenceState.fromName(json['state'] as String?),
  );
}
