import '../../models/keyword_profile.dart';

/// Abstract interface for keyword detection functionality
abstract class KeywordDetectionService {
  /// Trains the keyword detection model with the provided audio file
  /// [audioPath] path to the audio file containing the keyword
  /// Returns the trained [KeywordProfile]
  /// Throws [KeywordDetectionException] if training fails
  Future<KeywordProfile> trainKeyword(String audioPath);

  /// Starts listening for the trained keyword in background
  /// Throws [KeywordDetectionException] if listening fails to start
  Future<void> startListening();

  /// Stops keyword detection listening
  /// Throws [KeywordDetectionException] if stopping fails
  Future<void> stopListening();

  /// Stream that emits true when the keyword is detected
  Stream<bool> get keywordDetectedStream;

  /// Stream that emits confidence levels during detection (0.0 to 1.0)
  Stream<double> get confidenceStream;

  /// Checks if the service is currently listening for keywords
  bool get isListening;

  /// Gets the currently loaded keyword profile
  KeywordProfile? get currentProfile;

  /// Loads a previously trained keyword profile
  /// [profile] the keyword profile to load
  /// Throws [KeywordDetectionException] if loading fails
  Future<void> loadProfile(KeywordProfile profile);

  /// Updates the detection sensitivity/confidence threshold
  /// [threshold] confidence threshold between 0.0 and 1.0
  /// Throws [ArgumentError] if threshold is outside valid range
  Future<void> updateConfidenceThreshold(double threshold);

  /// Starts background listening mode with power optimization
  Future<void> startBackgroundListening();

  /// Stops background listening mode
  Future<void> stopBackgroundListening();

  /// Checks if currently in background listening mode
  bool get isBackgroundListening;

  /// Configures power consumption settings for background mode
  Future<void> configurePowerSettings({
    required bool lowPowerMode,
    required Duration maxBackgroundDuration,
  });

  /// Disposes of resources and stops listening
  Future<void> dispose();
}

/// Exception thrown when keyword detection operations fail
class KeywordDetectionException implements Exception {
  final String message;
  final dynamic originalError;

  const KeywordDetectionException(this.message, [this.originalError]);

  @override
  String toString() => 'KeywordDetectionException: $message';
}