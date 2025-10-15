import '../../models/keyword_profile.dart';

/// Abstract interface for keyword training functionality
abstract class KeywordTrainingService {
  /// Starts recording a keyword for training
  /// Returns Future that completes when recording starts successfully
  /// Throws [KeywordTrainingException] if recording fails to start
  Future<void> startKeywordRecording();

  /// Stops keyword recording and processes the audio for training
  /// [keywordText] the text representation of the spoken keyword
  /// Returns the trained [KeywordProfile]
  /// Throws [KeywordTrainingException] if processing fails
  Future<KeywordProfile> stopAndProcessKeyword(String keywordText);

  /// Stream of audio levels during keyword recording (0.0 to 1.0)
  /// Useful for providing visual feedback to users
  Stream<double> get audioLevelStream;

  /// Checks if keyword recording is currently active
  bool get isRecording;

  /// Gets the current recording duration
  Duration get recordingDuration;

  /// Validates if a keyword text is suitable for training
  /// [keywordText] the text to validate
  /// Returns validation result with error message if invalid
  KeywordValidationResult validateKeyword(String keywordText);

  /// Cancels current keyword recording without saving
  /// Throws [KeywordTrainingException] if cancellation fails
  Future<void> cancelRecording();

  /// Disposes of resources and stops any active recording
  Future<void> dispose();
}

/// Result of keyword validation
class KeywordValidationResult {
  final bool isValid;
  final String? errorMessage;

  const KeywordValidationResult.valid() : isValid = true, errorMessage = null;
  const KeywordValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Exception thrown when keyword training operations fail
class KeywordTrainingException implements Exception {
  final String message;
  final dynamic originalError;

  const KeywordTrainingException(this.message, [this.originalError]);

  @override
  String toString() => 'KeywordTrainingException: $message';
}