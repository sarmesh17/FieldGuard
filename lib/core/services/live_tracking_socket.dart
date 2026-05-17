import 'dart:async';

import 'package:fieldguard/core/constant/socket_constants.dart';
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

  SocketStatus _current = SocketStatus.idle;

  Stream<EmployeeLocationEvent> get onEmployeeLocation => _location.stream;
  Stream<EmployeeOnlineEvent> get onEmployeeOnline => _presence.stream;
  Stream<SocketStatus> get onStatus => _status.stream;
  SocketStatus get status => _current;
  bool get isConnected => _socket?.connected ?? false;

  void _setStatus(SocketStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  /// Connect (idempotent). Safe to call again — reuses the live socket.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      _setStatus(SocketStatus.error);
      return;
    }

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
      _setStatus(SocketStatus.connected);
      if (kDebugMode) debugPrint('[LiveSocket] connected');
    });

    socket.onDisconnect((_) {
      _setStatus(SocketStatus.disconnected);
      if (kDebugMode) debugPrint('[LiveSocket] disconnected');
    });

    socket.onConnectError((e) {
      _setStatus(SocketStatus.error);
      if (kDebugMode) debugPrint('[LiveSocket] connect_error: $e');
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

    _socket = socket;
    socket.connect();
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

  /// Disconnect but keep the singleton/streams reusable.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _setStatus(SocketStatus.idle);
  }
}
