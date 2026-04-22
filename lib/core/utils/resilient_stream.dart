import 'dart:async';

/// Keeps stream-based features alive when realtime subscriptions drop.
///
/// Supabase realtime can occasionally timeout on unstable connections
/// (especially on web). This wrapper auto-resubscribes with backoff instead
/// of propagating a terminal error to the UI.
Stream<T> resilientStream<T>(
  Stream<T> Function() streamFactory, {
  Duration initialRetryDelay = const Duration(seconds: 2),
  Duration maxRetryDelay = const Duration(seconds: 30),
}) async* {
  var retryDelay = initialRetryDelay;

  while (true) {
    try {
      yield* streamFactory();
      retryDelay = initialRetryDelay;
    } catch (_) {}

    await Future<void>.delayed(retryDelay);
    final nextDelaySeconds = retryDelay.inSeconds * 2;
    final cappedSeconds = nextDelaySeconds > maxRetryDelay.inSeconds
        ? maxRetryDelay.inSeconds
        : nextDelaySeconds;
    retryDelay = Duration(seconds: cappedSeconds);
  }
}
