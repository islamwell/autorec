import 'audio_quality_analyzer.dart';

/// Abstract interface for audio recording functionality
abstract class AudioRecordingService {
  /// Starts audio recording
  /// Returns Future that completes when recording starts successfully
  /// Throws [AudioRecordingException] if recording fails to start
  Future<void> startRecording();

  /// Stops audio recording and returns the file path of the recorded audio
  /// Returns the path to the saved recording file
  /// Throws [AudioRecordingException] if recording fails to stop or save
  Future<String> stopRecording();

  /// Stream of audio levels during recording (0.0 to 1.0)
  /// Useful for providing visual feedback to users
  Stream<double> get audioLevelStream;

  /// Stream of audio quality analysis results during recording
  /// Provides real-time noise detection and quality indicators
  Stream<AudioQualityResult> get audioQualityStream;

  /// Get current audio quality metrics
  /// Returns null if no analysis has been performed yet
  AudioQualityResult? get currentAudioQuality;

  /// Configures audio settings optimized for voice recording
  /// Sets sample rate, channels, and other parameters for voice capture
  Future<void> configureForVoice();

  /// Checks if recording is currently active
  bool get isRecording;

  /// Gets the current recording duration
  Duration get recordingDuration;

  /// Disposes of resources and stops any active recording
  Future<void> dispose();
}

/// Exception thrown when audio recording operations fail
class AudioRecordingException implements Exception {
  final String message;
  final dynamic originalError;

  const AudioRecordingException(this.message, [this.originalError]);

  @override
  String toString() => 'AudioRecordingException: $message';
}