/// Abstract interface for notification functionality
abstract class NotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Request notification permissions from the user
  Future<bool> requestPermissions();

  /// Show a notification for auto-stop timer completion
  Future<void> showAutoStopNotification({
    required String recordingPath,
    required Duration recordingDuration,
  });

  /// Show a notification for recording started
  Future<void> showRecordingStartedNotification();

  /// Show a notification for recording stopped
  Future<void> showRecordingStoppedNotification({
    required Duration recordingDuration,
  });

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Dispose of resources
  Future<void> dispose();
}

/// Exception thrown when notification operations fail
class NotificationException implements Exception {
  final String message;
  final dynamic originalError;

  const NotificationException(this.message, [this.originalError]);

  @override
  String toString() => 'NotificationException: $message';
}