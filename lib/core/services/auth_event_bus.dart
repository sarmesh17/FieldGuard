// Lightweight signal channel between the Dio interceptor and the auth notifier.
// The interceptor cannot access Riverpod, so it calls the static callback that
// LoginNotifier registers on construction.
class AuthEventBus {
  AuthEventBus._();

  static void Function()? _onSessionExpired;

  static void registerSessionExpiredCallback(void Function() callback) {
    _onSessionExpired = callback;
  }

  static void unregister() {
    _onSessionExpired = null;
  }

  static void triggerSessionExpired() {
    _onSessionExpired?.call();
  }
}
