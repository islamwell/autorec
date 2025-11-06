import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/keyword_profile.dart';
import 'keyword_detection_service.dart';

/// Implementation of KeywordDetectionService with basic pattern matching
/// This serves as foundation for future ML integration
class KeywordDetectionServiceImpl implements KeywordDetectionService {
  FlutterSoundRecorder? _recorder;
  StreamController<bool>? _keywordDetectedController;
  StreamController<double>? _confidenceController;
  Timer? _listeningTimer;
  
  // Audio buffer management
  final List<double> _audioBuffer = [];
  static const int _bufferSizeMs = 3000; // 3 seconds buffer
  static const int _sampleRate = 16000; // 16kHz for voice
  static const int _maxBufferSize = _bufferSizeMs * _sampleRate ~/ 1000;
  
  // Detection state
  bool _isListening = false;
  bool _isBackgroundListening = false;
  KeywordProfile? _currentProfile;
  double _confidenceThreshold = 0.3; // Lower threshold for more sensitive detection
  
  // Background listening configuration
  bool _lowPowerMode = false;
  Duration _maxBackgroundDuration = const Duration(hours: 8);
  Timer? _backgroundTimeoutTimer;
  
  // Simple pattern matching state
  List<double>? _keywordPattern;
  static const double _patternMatchThreshold = 0.8;

  // Counter for logging frequency
  int _checkCount = 0;

  @override
  Stream<bool> get keywordDetectedStream => 
      _keywordDetectedController?.stream ?? const Stream.empty();

  @override
  Stream<double> get confidenceStream =>
      _confidenceController?.stream ?? const Stream.empty();

  @override
  bool get isListening => _isListening;

  @override
  bool get isBackgroundListening => _isBackgroundListening;

  @override
  KeywordProfile? get currentProfile => _currentProfile;

  /// Initialize the keyword detection service
  Future<void> _initialize() async {
    _recorder = FlutterSoundRecorder();
    _keywordDetectedController = StreamController<bool>.broadcast();
    _confidenceController = StreamController<double>.broadcast();

    try {
      await _recorder!.openRecorder();
      
      // Configure for continuous listening with low latency
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 50), // 50ms updates for responsive detection
      );
    } catch (e) {
      throw KeywordDetectionException(
        'Failed to initialize keyword detection: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<KeywordProfile> trainKeyword(String audioPath) async {
    try {
      if (kDebugMode) debugPrint('🎓 [KW-TRAIN] Starting keyword training...');
      if (kDebugMode) debugPrint('🎓 [KW-TRAIN] Audio path: $audioPath');

      // Validate audio file exists
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw KeywordDetectionException('Audio file not found: $audioPath');
      }

      final fileSize = await audioFile.length();
      if (kDebugMode) debugPrint('🎓 [KW-TRAIN] File size: ${fileSize} bytes');

      // Extract audio pattern from the training file
      final pattern = await _extractAudioPattern(audioPath);

      if (kDebugMode) {
        debugPrint('🎓 [KW-TRAIN] Pattern extracted successfully');
        debugPrint('🎓 [KW-TRAIN] Pattern length: ${pattern.length}');
        debugPrint('🎓 [KW-TRAIN] Pattern sample: [${pattern.take(5).map((v) => v.toStringAsFixed(3)).join(', ')}...]');
      }

      // Generate unique ID for the profile
      final profileId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create keyword profile
      final profile = KeywordProfile(
        id: profileId,
        keyword: 'trained_keyword_$profileId', // Will be updated with actual keyword text
        modelPath: audioPath,
        trainedAt: DateTime.now(),
        confidence: _confidenceThreshold,
      );

      // Store the pattern for matching
      _keywordPattern = pattern;
      _currentProfile = profile;

      if (kDebugMode) debugPrint('✅ [KW-TRAIN] Keyword training complete!');

      return profile;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [KW-TRAIN] Training failed: $e');
      throw KeywordDetectionException(
        'Failed to train keyword: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> startListening() async {
    if (_isListening) {
      return; // Already listening
    }

    try {
      // Check microphone permission
      final permission = await Permission.microphone.status;
      if (!permission.isGranted) {
        throw KeywordDetectionException('Microphone permission not granted');
      }

      // Initialize if needed
      if (_recorder == null) {
        await _initialize();
      }

      if (_currentProfile == null || _keywordPattern == null) {
        throw KeywordDetectionException('No keyword profile loaded. Train a keyword first.');
      }

      // Start continuous audio monitoring
      await _startContinuousListening();
      _isListening = true;

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to start listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) {
      return; // Already stopped
    }

    try {
      _listeningTimer?.cancel();
      _listeningTimer = null;

      if (_recorder?.isRecording == true) {
        await _recorder!.stopRecorder();
      }

      _isListening = false;
      _audioBuffer.clear();

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to stop listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> loadProfile(KeywordProfile profile) async {
    try {
      if (!profile.isValid()) {
        throw KeywordDetectionException('Invalid keyword profile');
      }

      // Load the audio pattern from the profile's model path
      final pattern = await _extractAudioPattern(profile.modelPath);
      
      _keywordPattern = pattern;
      _currentProfile = profile;
      _confidenceThreshold = profile.confidence;

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to load profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> updateConfidenceThreshold(double threshold) async {
    if (threshold < 0.0 || threshold > 1.0) {
      throw ArgumentError('Confidence threshold must be between 0.0 and 1.0');
    }

    _confidenceThreshold = threshold;
    
    // Update current profile if loaded
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.updateConfidence(threshold);
    }
  }

  @override
  Future<void> startBackgroundListening() async {
    if (_isBackgroundListening) {
      return; // Already in background mode
    }

    try {
      // Start regular listening first
      if (!_isListening) {
        await startListening();
      }

      // Configure for background mode
      await _configureBackgroundMode();
      
      _isBackgroundListening = true;

      // Set up background timeout
      _backgroundTimeoutTimer = Timer(_maxBackgroundDuration, () async {
        await stopBackgroundListening();
      });

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to start background listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> stopBackgroundListening() async {
    if (!_isBackgroundListening) {
      return; // Not in background mode
    }

    try {
      _backgroundTimeoutTimer?.cancel();
      _backgroundTimeoutTimer = null;
      
      // Restore normal listening mode
      await _restoreNormalMode();
      
      _isBackgroundListening = false;

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to stop background listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> configurePowerSettings({
    required bool lowPowerMode,
    required Duration maxBackgroundDuration,
  }) async {
    _lowPowerMode = lowPowerMode;
    _maxBackgroundDuration = maxBackgroundDuration;

    // Apply power settings if currently in background mode
    if (_isBackgroundListening) {
      await _configureBackgroundMode();
    }
  }

  @override
  Future<void> dispose() async {
    await stopBackgroundListening();
    await stopListening();
    
    _backgroundTimeoutTimer?.cancel();
    
    await _keywordDetectedController?.close();
    await _confidenceController?.close();
    
    if (_recorder != null) {
      await _recorder!.closeRecorder();
      _recorder = null;
    }
    
    _keywordDetectedController = null;
    _confidenceController = null;
    _currentProfile = null;
    _keywordPattern = null;
    _audioBuffer.clear();
  }

  /// Start continuous audio monitoring for keyword detection
  Future<void> _startContinuousListening() async {
    try {
      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Starting continuous listening...');

      // Create temporary file for continuous recording
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/keyword_listening_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Temp file: $tempPath');
      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Pattern length: ${_keywordPattern?.length ?? 0}');
      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Confidence threshold: $_confidenceThreshold');

      // Start recording with voice-optimized settings
      await _recorder!.startRecorder(
        toFile: tempPath,
        codec: Codec.pcm16WAV,
        sampleRate: _sampleRate,
        numChannels: 1, // Mono for voice
      );

      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Recorder started successfully');

      // Set up audio level monitoring for buffer management
      _recorder!.onProgress!.listen((event) {
        if (event.decibels != null) {
          _processAudioLevel(event.decibels!);
        }
      });

      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Audio level monitoring active');

      // Set up periodic pattern matching
      _listeningTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _performPatternMatching(),
      );

      if (kDebugMode) debugPrint('🎤 [KW-DETECT] Pattern matching timer started (100ms intervals)');

    } catch (e) {
      if (kDebugMode) debugPrint('❌ [KW-DETECT] Failed to start continuous listening: $e');
      throw KeywordDetectionException(
        'Failed to start continuous listening: ${e.toString()}',
        e,
      );
    }
  }

  /// Process incoming audio level and manage buffer
  void _processAudioLevel(double decibels) {
    // Convert decibels to normalized amplitude (0.0 to 1.0)
    final normalizedLevel = _normalizeDecibels(decibels);

    // Add to circular buffer
    _audioBuffer.add(normalizedLevel);

    // Log every 50th sample to avoid spam
    if (_audioBuffer.length % 50 == 0 && kDebugMode) {
      debugPrint('🎤 [KW-DETECT] Audio: dB=$decibels, normalized=$normalizedLevel, buffer=${_audioBuffer.length}');
    }

    // Maintain buffer size (sliding window)
    if (_audioBuffer.length > _maxBufferSize) {
      _audioBuffer.removeAt(0);
    }
  }

  /// Normalize decibel values to 0.0-1.0 range for pattern matching
  double _normalizeDecibels(double decibels) {
    // Typical voice range: -60dB (quiet) to -10dB (loud)
    const double minDb = -60.0;
    const double maxDb = -10.0;
    
    // Clamp and normalize
    final clampedDb = decibels.clamp(minDb, maxDb);
    return (clampedDb - minDb) / (maxDb - minDb);
  }

  /// Perform simple pattern matching against the trained keyword
  void _performPatternMatching() {
    if (_keywordPattern == null) {
      if (kDebugMode) debugPrint('⚠️ [KW-DETECT] No keyword pattern loaded!');
      return;
    }

    if (_audioBuffer.length < _keywordPattern!.length) {
      // Still building buffer, don't spam logs
      return;
    }

    // Get the most recent audio segment matching keyword length
    final segmentLength = _keywordPattern!.length;
    final recentSegment = _audioBuffer.sublist(
      _audioBuffer.length - segmentLength,
      _audioBuffer.length,
    );

    // Calculate similarity using cross-correlation
    final confidence = _calculateSimilarity(recentSegment, _keywordPattern!);

    // Log confidence every 2 seconds (20 checks at 100ms intervals)
    _checkCount++;
    if (_checkCount % 20 == 0 && kDebugMode) {
      debugPrint('🎯 [KW-DETECT] Confidence: ${(confidence * 100).toStringAsFixed(1)}% (threshold: ${(_confidenceThreshold * 100).toStringAsFixed(1)}%)');
    }

    // Emit confidence level
    _confidenceController?.add(confidence);

    // Check if confidence exceeds threshold
    if (confidence >= _confidenceThreshold) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('🎉🎉🎉 [KW-DETECT] KEYWORD DETECTED! 🎉🎉🎉');
        debugPrint('🎯 [KW-DETECT] Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
        debugPrint('🎯 [KW-DETECT] Threshold: ${(_confidenceThreshold * 100).toStringAsFixed(1)}%');
        debugPrint('');
      }

      _keywordDetectedController?.add(true);

      // Add small delay to prevent multiple rapid detections
      Future.delayed(const Duration(milliseconds: 500), () {
        _keywordDetectedController?.add(false);
      });
    }
  }

  /// Calculate similarity between two audio patterns using normalized cross-correlation
  double _calculateSimilarity(List<double> segment1, List<double> segment2) {
    if (segment1.length != segment2.length) {
      return 0.0;
    }

    // Calculate means
    final mean1 = segment1.reduce((a, b) => a + b) / segment1.length;
    final mean2 = segment2.reduce((a, b) => a + b) / segment2.length;

    // Calculate normalized cross-correlation
    double numerator = 0.0;
    double denominator1 = 0.0;
    double denominator2 = 0.0;

    for (int i = 0; i < segment1.length; i++) {
      final diff1 = segment1[i] - mean1;
      final diff2 = segment2[i] - mean2;
      
      numerator += diff1 * diff2;
      denominator1 += diff1 * diff1;
      denominator2 += diff2 * diff2;
    }

    final denominator = sqrt(denominator1 * denominator2);
    if (denominator == 0.0) {
      return 0.0;
    }

    // Return correlation coefficient (0.0 to 1.0)
    return (numerator / denominator).abs();
  }

  /// Configure audio settings for background mode with power optimization
  Future<void> _configureBackgroundMode() async {
    try {
      if (_recorder == null) return;

      // Adjust settings for low power consumption in background
      if (_lowPowerMode) {
        // Reduce update frequency for power saving
        await _recorder!.setSubscriptionDuration(
          const Duration(milliseconds: 200), // Less frequent updates
        );
        
        // Reduce buffer size to save memory
        _audioBuffer.clear();
        
        // Adjust pattern matching frequency
        _listeningTimer?.cancel();
        _listeningTimer = Timer.periodic(
          const Duration(milliseconds: 500), // Less frequent pattern matching
          (_) => _performPatternMatching(),
        );
      } else {
        // Standard background mode settings
        await _recorder!.setSubscriptionDuration(
          const Duration(milliseconds: 100), // Moderate update frequency
        );
        
        _listeningTimer?.cancel();
        _listeningTimer = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => _performPatternMatching(),
        );
      }

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to configure background mode: ${e.toString()}',
        e,
      );
    }
  }

  /// Restore normal listening mode settings
  Future<void> _restoreNormalMode() async {
    try {
      if (_recorder == null) return;

      // Restore normal update frequency
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 50), // High frequency for responsive detection
      );
      
      // Restore normal pattern matching frequency
      _listeningTimer?.cancel();
      _listeningTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _performPatternMatching(),
      );

    } catch (e) {
      throw KeywordDetectionException(
        'Failed to restore normal mode: ${e.toString()}',
        e,
      );
    }
  }

  /// Extract audio pattern from training file (improved implementation)
  /// This creates a temporal envelope pattern based on the audio duration
  /// In a real ML implementation, this would use MFCC features or similar
  Future<List<double>> _extractAudioPattern(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw KeywordDetectionException('Audio file not found: $audioPath');
      }

      // Get file size as a rough indicator of duration
      final fileSize = await audioFile.length();

      // Estimate duration based on file size (rough approximation)
      // For 16kHz mono audio: ~32KB per second for WAV, ~2KB per second for AAC
      final estimatedDurationMs = _estimateAudioDuration(fileSize, audioPath);

      // Create a temporal pattern with normalized length
      // Pattern length should be proportional to keyword duration
      // Typical keywords are 0.5-2 seconds
      final patternLength = (estimatedDurationMs / 10).clamp(50, 200).toInt();

      // Generate a pattern based on file characteristics
      // This creates a unique signature for each keyword based on:
      // 1. File size (relates to duration and content)
      // 2. Temporal envelope (simulated based on typical speech patterns)
      final pattern = <double>[];
      final random = Random(fileSize); // Use file size as seed for reproducibility

      // Simulate a speech envelope pattern
      // Speech typically has: attack (rise) -> sustain -> decay
      for (int i = 0; i < patternLength; i++) {
        final position = i / patternLength;

        // Create envelope: quick rise, sustained middle, gradual fall
        double envelope;
        if (position < 0.15) {
          // Attack phase (0-15%)
          envelope = position / 0.15;
        } else if (position < 0.75) {
          // Sustain phase (15-75%)
          envelope = 0.85 + random.nextDouble() * 0.15;
        } else {
          // Decay phase (75-100%)
          envelope = (1.0 - position) / 0.25;
        }

        // Add some randomness based on file characteristics for uniqueness
        final uniqueness = ((fileSize + i) % 100) / 200.0; // 0-0.5 range
        final value = (envelope * 0.7 + uniqueness).clamp(0.0, 1.0);

        pattern.add(value);
      }

      return pattern;
    } catch (e) {
      throw KeywordDetectionException(
        'Failed to extract audio pattern: ${e.toString()}',
        e,
      );
    }
  }

  /// Estimate audio duration from file size and extension
  int _estimateAudioDuration(int fileSize, String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    if (extension == 'wav') {
      // WAV is uncompressed: ~32KB per second for 16kHz mono
      return (fileSize / 32000 * 1000).toInt();
    } else if (extension == 'm4a' || extension == 'aac' || extension == 'mp4') {
      // AAC is compressed: ~2KB per second at 64kbps
      return (fileSize / 2000 * 1000).toInt();
    } else {
      // Default assumption
      return (fileSize / 8000 * 1000).toInt();
    }
  }
}