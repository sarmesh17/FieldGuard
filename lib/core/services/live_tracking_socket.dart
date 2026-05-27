import 'dart:async';

import 'package:fieldguard/core/constant/socket_constants.dart';
import 'package:fieldguard/core/services/session.dart';
import 'package:fieldguard/core/services/token_refresher.dart';
import 'package:fieldguard/core/services/token_storage.dart';
import 'package:fieldguard/features/live_tracking/data/models/live_location.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum SocketStatus { idle, connecting, connected, disconnected, error }

/// Live-tracking Socket.IO client.
///
/// One shared instance for the whole app — viewers (managers/admins) listen
/// for team movement, field users emit their own location. The server is
/// expected to auto-join the socket to the right rooms based on the auth
/// token, so the client never emits a join event.
class LiveTrackingSocket {
  LiveTrackingSocket._();
  static final LiveTrackingSocket instance = LiveTrackingSocket._();

  io.Socket? _socket;

  final _location = StreamController<EmployeeLocationEvent>.broadcast();
  final _presence = StreamController<EmployeeOnlineEvent>.broadcast();
  final _status = StreamController<SocketStatus>.broadcast();
  final _taskLocation = StreamController<TaskLocationEvent>.broadcast();
  final _taskStatus = StreamController<TaskStatusChangedEvent>.broadcast();

  SocketStatus _current = SocketStatus.idle;
  bool _reauthing = false;
  int _authRetries = 0;

  /// Task rooms this client is watching. Re-joined automatically whenever
  /// the socket (re)connects — a token refresh rebuilds the socket and
  /// would otherwise silently drop the `task:<id>:viewers` membership.
  final Set<int> _watchedTasks = {};

  Stream<EmployeeLocationEvent> get onEmployeeLocation => _location.stream;
  Stream<EmployeeOnlineEvent> get onEmployeeOnline => _presence.stream;
  Stream<TaskLocationEvent> get onTaskLocation => _taskLocation.stream;
  Stream<TaskStatusChangedEvent> get onTaskStatusChanged =>
      _taskStatus.stream;
  Stream<SocketStatus> get onStatus => _status.stream;
  SocketStatus get status => _current;
  bool get isConnected => _socket?.connected ?? false;

  void _setStatus(SocketStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  /// Connect (idempotent). Safe to call again — reuses the live socket.
  ///
  /// If the access token expired while the app was backgrounded it is
  /// refreshed FIRST, so resuming reconnects cleanly without a failed
  /// handshake. Never logs the user out — that is the REST flow's job.
  Future<void> connect() async {
    if (_socket?.connected ?? false) return;

    if (await Session.isAccessTokenExpired()) {
      await TokenRefresher.refresh();
    }

    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      _setStatus(SocketStatus.error);
      return;
    }
    _openSocket(token);
  }

  void _openSocket(String token) {
    // Tear down any half-open socket before reconnecting.
    _socket?.dispose();

    _setStatus(SocketStatus.connecting);

    final socket = io.io(
      SocketConstants.url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(SocketConstants.path)
          .disableAutoConnect()
          // Backend handshake: io(url, { auth: { token } }).
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
      _authRetries = 0;
      _setStatus(SocketStatus.connected);
      // Rejoin any task rooms — the socket may have just been rebuilt
      // (token refresh / reconnect), which drops server-side rooms.
      for (final taskId in _watchedTasks) {
        socket.emit(SocketConstants.taskWatch, {'taskId': taskId});
      }
      if (kDebugMode) debugPrint('[LiveSocket] connected');
    });

    socket.onDisconnect((_) {
      _setStatus(SocketStatus.disconnected);
      if (kDebugMode) debugPrint('[LiveSocket] disconnected');
    });

    socket.onConnectError((e) {
      if (kDebugMode) debugPrint('[LiveSocket] connect_error: $e');
      _handleAuthFailure();
    });

    socket.onError((e) {
      if (kDebugMode) debugPrint('[LiveSocket] error: $e');
    });

    socket.on(SocketConstants.employeeLocation, (data) {
      final event = EmployeeLocationEvent.tryParse(data);
      if (event != null && !_location.isClosed) _location.add(event);
    });

    socket.on(SocketConstants.employeeOnline, (data) {
      final event = EmployeeOnlineEvent.tryParse(data, online: true);
      if (event != null && !_presence.isClosed) _presence.add(event);
    });

    socket.on(SocketConstants.employeeOffline, (data) {
      final event = EmployeeOnlineEvent.tryParse(data, online: false);
      if (event != null && !_presence.isClosed) _presence.add(event);
    });

    socket.on(SocketConstants.taskLocation, (data) {
      final event = TaskLocationEvent.tryParse(data);
      if (event != null && !_taskLocation.isClosed) {
        _taskLocation.add(event);
      }
    });

    socket.on(SocketConstants.taskStatusChanged, (data) {
      final event = TaskStatusChangedEvent.tryParse(data);
      if (event != null && !_taskStatus.isClosed) _taskStatus.add(event);
    });

    _socket = socket;
    socket.connect();
  }

  /// Refresh the token and rebuild the socket when the handshake fails
  /// because the access token expired. Capped so a server outage doesn't
  /// spin the refresh endpoint; [ensureConnected] (on resume) resets it.
  Future<void> _handleAuthFailure() async {
    _setStatus(SocketStatus.error);
    if (_reauthing || _authRetries >= 3) return;
    _reauthing = true;
    _authRetries++;
    try {
      final result = await TokenRefresher.refresh();
      if (result.outcome == RefreshOutcome.refreshed) {
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          _authRetries = 0;
          _openSocket(token);
        }
      }
      // invalid  → stop; the REST flow owns real session expiry.
      // network  → socket.io keeps retrying; resume will recover.
    } finally {
      _reauthing = false;
    }
  }

  /// Call when the app returns to the foreground so tracking keeps flowing
  /// even if the socket dropped (or its token expired) while backgrounded.
  Future<void> ensureConnected() async {
    if (_socket?.connected ?? false) return;
    _authRetries = 0;
    await connect();
  }

  /// Start this device's own field session.
  void emitTrackingStart() {
    _socket?.emit(SocketConstants.trackingStart, <String, dynamic>{});
  }

  /// Stop this device's own field session.
  void emitTrackingStop() {
    _socket?.emit(SocketConstants.trackingStop, <String, dynamic>{});
  }

  /// Push this device's current location to the server.
  void emitLocationUpdate({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    _socket?.emit(SocketConstants.locationUpdate, {
      'latitude': latitude,
      'longitude': longitude,
      'speed': ?speed,
      'heading': ?heading,
      'accuracy': ?accuracy,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Start watching one task's assignee (Admin/Manager only). Joins the
  /// `task:<id>:viewers` room; remembered so it survives reconnects.
  void emitTaskWatch(int taskId) {
    _watchedTasks.add(taskId);
    _socket?.emit(SocketConstants.taskWatch, {'taskId': taskId});
  }

  /// Stop watching a task. Leaves the room and forgets it.
  void emitTaskUnwatch(int taskId) {
    _watchedTasks.remove(taskId);
    _socket?.emit(SocketConstants.taskUnwatch, {'taskId': taskId});
  }

  /// Disconnect but keep the singleton/streams reusable.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _authRetries = 0;
    _setStatus(SocketStatus.idle);
  }
}
