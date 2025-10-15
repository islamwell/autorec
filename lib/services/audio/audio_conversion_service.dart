import 'dart:io';

/// Enum representing different audio compression levels
enum CompressionLevel {
  low,    // Minimal compression, highest quality
  medium, // Balanced compression and quality
  high,   // Maximum compression, lower quality
}

/// Enum representing supported audio formats
enum AudioFormat {
  wav,
  mp3,
  aac,
  m4a,
}

/// Configuration for audio conversion
class AudioConversionConfig {
  final AudioFormat outputFormat;
  final CompressionLevel compressionLevel;
  final int? bitrate; // kbps, null for default
  final int? sampleRate; // Hz, null for default
  final bool mono; // true for mono, false for stereo
  
  const AudioConversionConfig({
    required this.outputFormat,
    this.compressionLevel = CompressionLevel.medium,
    this.bitrate,
    this.sampleRate,
    this.mono = true,
  });
  
  /// Default configuration for voice recordings
  static const AudioConversionConfig voiceOptimized = AudioConversionConfig(
    outputFormat: AudioFormat.mp3,
    compressionLevel: CompressionLevel.medium,
    bitrate: 64, // 64 kbps is sufficient for voice
    sampleRate: 16000, // 16kHz for voice
    mono: true,
  );
  
  /// High quality configuration
  static const AudioConversionConfig highQuality = AudioConversionConfig(
    outputFormat: AudioFormat.mp3,
    compressionLevel: CompressionLevel.low,
    bitrate: 128,
    sampleRate: 44100,
    mono: false,
  );
  
  /// Maximum compression configuration
  static const AudioConversionConfig maxCompression = AudioConversionConfig(
    outputFormat: AudioFormat.mp3,
    compressionLevel: CompressionLevel.high,
    bitrate: 32,
    sampleRate: 8000,
    mono: true,
  );
}

/// Abstract interface for audio conversion operations
abstract class AudioConversionService {
  /// Converts audio file to specified format and compression
  /// [inputPath] path to the input audio file
  /// [outputPath] path where converted file should be saved
  /// [config] conversion configuration
  /// Returns the actual output path (may differ from requested if extension changed)
  /// Throws [AudioConversionException] if conversion fails
  Future<String> convertAudio(
    String inputPath,
    String outputPath,
    AudioConversionConfig config,
  );
  
  /// Compresses an existing audio file
  /// [inputPath] path to the input audio file
  /// [compressionLevel] level of compression to apply
  /// Returns the path to the compressed file
  /// Throws [AudioConversionException] if compression fails
  Future<String> compressAudio(String inputPath, CompressionLevel compressionLevel);
  
  /// Gets the estimated file size after conversion
  /// [inputPath] path to the input audio file
  /// [config] conversion configuration
  /// Returns estimated size in bytes
  Future<int> getEstimatedOutputSize(String inputPath, AudioConversionConfig config);
  
  /// Checks if a specific audio format is supported
  /// [format] audio format to check
  /// Returns true if supported, false otherwise
  bool isFormatSupported(AudioFormat format);
  
  /// Gets the file extension for an audio format
  /// [format] audio format
  /// Returns the file extension (without dot)
  String getFileExtension(AudioFormat format);
  
  /// Validates if an audio file is in the expected format
  /// [filePath] path to the audio file
  /// [expectedFormat] expected audio format
  /// Returns true if file matches expected format
  Future<bool> validateAudioFormat(String filePath, AudioFormat expectedFormat);
}

/// Exception thrown when audio conversion operations fail
class AudioConversionException implements Exception {
  final String message;
  final dynamic originalError;

  const AudioConversionException(this.message, [this.originalError]);

  @override
  String toString() => 'AudioConversionException: $message';
}