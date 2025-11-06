import '../../models/scheduled_recording.dart';

/// Service interface for managing scheduled recordings
abstract class ScheduledRecordingService {
  /// Get all scheduled recordings
  Future<List<ScheduledRecording>> getScheduledRecordings();

  /// Create a new scheduled recording
  Future<ScheduledRecording> createScheduledRecording(ScheduledRecording recording);

  /// Update an existing scheduled recording
  Future<ScheduledRecording> updateScheduledRecording(ScheduledRecording recording);

  /// Delete a scheduled recording
  Future<void> deleteScheduledRecording(String id);

  /// Toggle a scheduled recording on/off
  Future<ScheduledRecording> toggleScheduledRecording(String id, bool enabled);

  /// Get the next scheduled recording that will trigger
  Future<ScheduledRecording?> getNextScheduledRecording();

  /// Check if a scheduled recording should trigger now
  bool shouldTriggerNow(ScheduledRecording recording);

  /// Calculate the next trigger time for a scheduled recording
  DateTime getNextTriggerTime(ScheduledRecording recording);

  /// Dispose of the service and cancel any active timers
  Future<void> dispose();
}

/// Exception thrown when scheduled recording operations fail
class ScheduledRecordingException implements Exception {
  final String message;
  final Object? cause;

  ScheduledRecordingException(this.message, [this.cause]);

  @override
  String toString() => 'ScheduledRecordingException: $message${cause != null ? '\nCause: $cause' : ''}';
}
