import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Detects whether the app is running on a rooted (Android) or jailbroken (iOS)
/// device.
///
/// FieldGuard handles location-sensitive field data and geofence enforcement,
/// so compromised devices are blocked from launching the app entirely.
class RootDetectionService {
  const RootDetectionService._();

  /// Returns `true` if the device appears to be rooted / jailbroken.
  ///
  /// Fails *open* (returns `false`) when the platform check itself throws — for
  /// example, the plugin isn't available on the running platform — so a plugin
  /// or method-channel error can never lock out legitimate users. Note the
  /// underlying plugin already fails *closed* at the protocol level (it reports
  /// compromised when the native side can't make a determination).
  static Future<bool> isDeviceCompromised() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e, st) {
      debugPrint('Root detection failed, allowing launch: $e\n$st');
      return false;
    }
  }
}
