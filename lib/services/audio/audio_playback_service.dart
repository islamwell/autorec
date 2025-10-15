/// Enum representing different playback states
enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

/// Abstract interface for audio playback functionality
abstract class AudioPlaybackService {
  /// Plays audio from the specified file path
  /// Throws [AudioPlaybackException] if playback fails to start
  Future<void> play(String filePath);

  /// Pauses the current playback
  /// Throws [AudioPlaybackException] if pause operation fails
  Future<void> pause();

  /// Resumes paused playback
  /// Throws [AudioPlaybackException] if resume operation fails
  Future<void> resume();

  /// Stops playback and resets position to beginning
  /// Throws [AudioPlaybackException] if stop operation fails
  Future<void> stop();

  /// Sets the playback speed (0.5x to 2.0x)
  /// [speed] must be between 0.5 and 2.0
  /// Throws [ArgumentError] if speed is outside valid range
  Future<void> setSpeed(double speed);

  /// Seeks to a specific position in the audio
  /// [position] must be within the audio duration
  /// Throws [ArgumentError] if position is invalid
  Future<void> seekTo(Duration position);

  /// Stream of current playback position
  Stream<Duration> get positionStream;

  /// Stream of current playback state
  Stream<PlaybackState> get stateStream;

  /// Gets the total duration of the currently loaded audio
  Duration? get duration;

  /// Gets the current playback position
  Duration get position;

  /// Gets the current playback state
  PlaybackState get state;

  /// Gets the current playback speed
  double get speed;

  /// Disposes of resources and stops playback
  Future<void> dispose();
}

/// Exception thrown when audio playback operations fail
class AudioPlaybackException implements Exception {
  final String message;
  final dynamic originalError;

  const AudioPlaybackException(this.message, [this.originalError]);

  @override
  String toString() => 'AudioPlaybackException: $message';
}