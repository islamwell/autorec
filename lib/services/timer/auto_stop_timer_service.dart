import 'dart:async';

/// Abstract interface for auto-stop timer functionality
abstract class AutoStopTimerService {
  /// Starts the auto-stop timer with the specified duration
  /// Returns a stream that emits remaining time updates
  Stream<Duration> startTimer(Duration duration);

  /// Stops the current timer
  void stopTimer();

  /// Gets the remaining time on the current timer
  Duration get remainingTime;

  /// Checks if a timer is currently active
  bool get isActive;

  /// Stream that emits when the timer completes (reaches zero)
  Stream<void> get onTimerComplete;

  /// Disposes of resources
  void dispose();
}

/// Exception thrown when timer operations fail
class AutoStopTimerException implements Exception {
  final String message;
  final dynamic originalError;

  const AutoStopTimerException(this.message, [this.originalError]);

  @override
  String toString() => 'AutoStopTimerException: $message';
}