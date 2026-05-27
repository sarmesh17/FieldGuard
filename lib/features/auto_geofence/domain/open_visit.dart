import 'package:fieldguard/features/auto_geofence/domain/geo_fix.dart';

/// An in-progress geofence visit, persisted the moment the manager enters
/// a target.
///
/// It carries everything needed to (a) continue exit detection after a
/// process restart and (b) recover — close the visit from the last known
/// in-geofence fix when detection was interrupted (kill / reboot /
/// permission revoked / GPS lost).
class OpenVisit {
  /// Client-generated UUIDv4 idempotency key. The backend dedupes on it,
  /// so a retried upload after a dropped response never duplicates a row.
  final String visitId;
  final int taskId;
  final int? shopId;

  /// Geofence centre captured at entry — exit detection uses this so the
  /// visit's geometry never depends on a later task poll still listing
  /// the target.
  final double centerLatitude;
  final double centerLongitude;

  final DateTime enteredAtUtc;
  final double enterLatitude;
  final double enterLongitude;

  /// Most recent fix confirmed inside the geofence. This is the recovery
  /// anchor: an interrupted visit is closed at this fix's time/location
  /// with `exitEstimated = true`.
  final GeoFix lastInsideFix;

  /// Exit evidence accumulated so far; reset whenever a fix lands back
  /// inside the geofence.
  final int consecutiveOutsideFixes;
  final DateTime? firstOutsideAtUtc;

  const OpenVisit({
    required this.visitId,
    required this.taskId,
    required this.shopId,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.enteredAtUtc,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.lastInsideFix,
    this.consecutiveOutsideFixes = 0,
    this.firstOutsideAtUtc,
  });

  OpenVisit copyWith({
    GeoFix? lastInsideFix,
    int? consecutiveOutsideFixes,
    DateTime? firstOutsideAtUtc,
    bool clearOutsideEvidence = false,
  }) {
    return OpenVisit(
      visitId: visitId,
      taskId: taskId,
      shopId: shopId,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      enteredAtUtc: enteredAtUtc,
      enterLatitude: enterLatitude,
      enterLongitude: enterLongitude,
      lastInsideFix: lastInsideFix ?? this.lastInsideFix,
      consecutiveOutsideFixes: clearOutsideEvidence
          ? 0
          : (consecutiveOutsideFixes ?? this.consecutiveOutsideFixes),
      firstOutsideAtUtc: clearOutsideEvidence
          ? null
          : (firstOutsideAtUtc ?? this.firstOutsideAtUtc),
    );
  }

  Map<String, dynamic> toJson() => {
    'visitId': visitId,
    'taskId': taskId,
    'shopId': shopId,
    'centerLatitude': centerLatitude,
    'centerLongitude': centerLongitude,
    'enteredAtUtc': enteredAtUtc.toUtc().toIso8601String(),
    'enterLatitude': enterLatitude,
    'enterLongitude': enterLongitude,
    'lastInsideFix': lastInsideFix.toJson(),
    'consecutiveOutsideFixes': consecutiveOutsideFixes,
    'firstOutsideAtUtc': firstOutsideAtUtc?.toUtc().toIso8601String(),
  };

  factory OpenVisit.fromJson(Map<String, dynamic> json) => OpenVisit(
    visitId: json['visitId'] as String,
    taskId: (json['taskId'] as num).toInt(),
    shopId: (json['shopId'] as num?)?.toInt(),
    centerLatitude: (json['centerLatitude'] as num).toDouble(),
    centerLongitude: (json['centerLongitude'] as num).toDouble(),
    enteredAtUtc: DateTime.parse(json['enteredAtUtc'] as String).toUtc(),
    enterLatitude: (json['enterLatitude'] as num).toDouble(),
    enterLongitude: (json['enterLongitude'] as num).toDouble(),
    lastInsideFix: GeoFix.fromJson(
      json['lastInsideFix'] as Map<String, dynamic>,
    ),
    consecutiveOutsideFixes:
        (json['consecutiveOutsideFixes'] as num?)?.toInt() ?? 0,
    firstOutsideAtUtc: json['firstOutsideAtUtc'] == null
        ? null
        : DateTime.parse(json['firstOutsideAtUtc'] as String).toUtc(),
  );
}
