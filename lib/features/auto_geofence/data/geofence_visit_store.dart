import 'dart:convert';

import 'package:fieldguard/features/auto_geofence/domain/open_visit.dart';
import 'package:fieldguard/features/auto_geofence/domain/geofence_visit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// On-disk persistence for the auto-geofence subsystem.
///
/// Uses `flutter_secure_storage` (encrypted at rest, already a project
/// dependency) so the open visit and the retry queue survive app kill,
/// reboot, token refresh and logout/login. Two keys:
///   * [_openVisitKey] — the single in-progress visit (absent when none).
///   * [_queueKey]      — JSON array of [QueuedVisit].
///
/// All reads tolerate missing/corrupt data and degrade to null / empty
/// rather than throwing — a storage glitch must never crash tracking.
class GeofenceVisitStore {
  static const _openVisitKey = 'geofence_open_visit';
  static const _queueKey = 'geofence_visit_queue';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<OpenVisit?> loadOpenVisit() async {
    try {
      final raw = await _storage.read(key: _openVisitKey);
      if (raw == null || raw.isEmpty) return null;
      return OpenVisit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] open-visit read failed: $e');
      return null;
    }
  }

  Future<void> saveOpenVisit(OpenVisit visit) async {
    try {
      await _storage.write(
        key: _openVisitKey,
        value: jsonEncode(visit.toJson()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] open-visit write failed: $e');
    }
  }

  Future<void> clearOpenVisit() async {
    try {
      await _storage.delete(key: _openVisitKey);
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] open-visit clear failed: $e');
    }
  }

  Future<List<QueuedVisit>> loadQueue() async {
    try {
      final raw = await _storage.read(key: _queueKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => QueuedVisit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] queue read failed: $e');
      return [];
    }
  }

  Future<void> saveQueue(List<QueuedVisit> queue) async {
    try {
      await _storage.write(
        key: _queueKey,
        value: jsonEncode(queue.map((q) => q.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] queue write failed: $e');
    }
  }
}
