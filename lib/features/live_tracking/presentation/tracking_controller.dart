import 'package:fieldguard/core/services/live_tracking_socket.dart';
import 'package:fieldguard/core/services/location_tracker.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

/// Immutable state for the app-wide live-tracking switch.
class TrackingState {
  final bool active;
  final bool busy;
  const TrackingState({this.active = false, this.busy = false});

  TrackingState copyWith({bool? active, bool? busy}) =>
      TrackingState(active: active ?? this.active, busy: busy ?? this.busy);
}

/// App-wide live-tracking switch.
///
/// Previously this lived inside the Routes screen; it now lives above any one
/// screen so the toggle on the Home screen keeps the field session running as
/// the user navigates around the app. Field agents (EMPLOYEE / MANAGER)
/// broadcast their location to the team map while active; the Routes map just
/// reacts to [TrackingState.active] to show the puck + draw the live route.
class TrackingController extends StateNotifier<TrackingState>
    with WidgetsBindingObserver {
  TrackingController() : super(const TrackingState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final _socket = LiveTrackingSocket.instance;
  final _tracker = LocationTracker.instance;

  // True only while this device is emitting its own location (field agents).
  bool _broadcasting = false;

  Future<bool> start() async {
    if (state.busy || state.active) return state.active;
    state = state.copyWith(busy: true);
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        state = const TrackingState();
        return false;
      }

      // Only managers go to the field and broadcast their location to the
      // team map. (The app's only roles are MANAGER and ADMIN; the toggle is
      // shown to managers only, so this is also a belt-and-braces guard.)
      final role = (await Session.role())?.toUpperCase() ?? '';
      if (role == 'MANAGER') {
        await _socket.connect();
        final ok = await _tracker.start(onPosition: _onPosition);
        if (!ok) {
          state = const TrackingState();
          return false;
        }
        _socket.emitTrackingStart();
        _broadcasting = true;
      }

      state = const TrackingState(active: true);
      return true;
    } catch (_) {
      state = const TrackingState();
      return false;
    }
  }

  Future<void> stop() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    if (_broadcasting) {
      _socket.emitTrackingStop();
      await _tracker.stop();
      _broadcasting = false;
    }
    state = const TrackingState();
  }

  void _onPosition(geo.Position p) {
    _socket.emitLocationUpdate(
      latitude: p.latitude,
      longitude: p.longitude,
      speed: p.speed,
      heading: p.heading,
      accuracy: p.accuracy,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Re-establish the socket on resume so a session that dropped while
    // backgrounded keeps broadcasting.
    if (lifecycle == AppLifecycleState.resumed && _broadcasting) {
      _socket.ensureConnected().then((_) {
        if (_broadcasting) _socket.emitTrackingStart();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Global (not auto-disposed) so tracking survives screen changes.
final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>(
      (ref) => TrackingController(),
    );
