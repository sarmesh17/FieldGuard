import 'dart:async';

/// Serialises async sections so two interleaved operations never perform a
/// stale read-modify-write on the persisted geofence state.
///
/// Both the position-fix handler and the retry queue mutate disk-backed
/// state across `await` points; without serialisation a fix arriving
/// mid-write (or a queue flush racing an enqueue) could clobber the other.
class Mutex {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _tail;
    // The next waiter chains off this one's completion (errors swallowed
    // here so one failed section never wedges the whole queue).
    _tail = completer.future.then<void>((_) {}, onError: (_) {});
    previous.whenComplete(() {
      action().then(completer.complete, onError: completer.completeError);
    });
    return completer.future;
  }
}
