import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_recording_service.dart';
import 'audio_quality_analyzer.dart';
import 'ios_audio_session_service.dart';

/// Implementation of AudioRecordingService using flutter_sound
class AudioRecordingServiceImpl implements AudioRecordingService {
  FlutterSoundRecorder? _recorder;
  StreamController<double>? _audioLevelController;
  StreamController<AudioQualityResult>? _audioQualityController;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;
  bool _isInitialized = false;
  double? _lastNormalizedLevel;
  final AudioQualityAnalyzer _qualityAnalyzer = AudioQualityAnalyzer();

  @override
  Stream<double> get audioLevelStream => 
      _audioLevelController?.stream ?? const Stream.empty();

  @override
  Stream<AudioQualityResult> get audioQualityStream =>
      _audioQualityController?.stream ?? const Stream.empty();

  @override
  AudioQualityResult? get currentAudioQuality => _qualityAnalyzer.currentQuality;

  @override
  bool get isRecording => _recorder?.isRecording ?? false;

  @override
  Duration get recordingDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Initialize the recorder with proper configuration
  Future<void> _initialize() async {
    if (_isInitialized) return;

    _recorder = FlutterSoundRecorder();
    _audioLevelController = StreamController<double>.broadcast();
    _audioQualityController = StreamController<AudioQualityResult>.broadcast();

    try {
      await _recorder!.openRecorder();
      await configureForVoice();
      _isInitialized = true;
    } catch (e) {
      throw AudioRecordingException(
        'Failed to initialize audio recorder: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> configureForVoice() async {
    if (_recorder == null) {
      throw AudioRecordingException('Recorder not initialized');
    }

    try {
      // Configure for voice recording optimization
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100), // Update audio levels every 100ms
      );
    } catch (e) {
      throw AudioRecordingException(
        'Failed to configure recorder for voice: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> startRecording() async {
    try {
      // Check microphone permission
      final permission = await Permission.microphone.status;
      if (!permission.isGranted) {
        throw AudioRecordingException('Microphone permission not granted');
      }

      // Configure iOS audio session for recording
      await IOSAudioSessionService.configureForRecording();
      await IOSAudioSessionService.activateSession();

      // Initialize if needed
      await _initialize();

      if (_recorder == null) {
        throw AudioRecordingException('Recorder not initialized');
      }

      if (isRecording) {
        throw AudioRecordingException('Recording already in progress');
      }

      // Generate unique file path
      _currentRecordingPath = await _generateRecordingPath();

      // Start recording with voice-optimized settings
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4, // Good compression for voice
        sampleRate: 16000, // Optimized for voice (16kHz)
        numChannels: 1, // Mono recording
        bitRate: 64000, // Good quality for voice
      );

      _recordingStartTime = DateTime.now();

      // Reset quality analyzer for new recording
      _qualityAnalyzer.reset();
      _lastNormalizedLevel = null;

      // Start audio level monitoring
      _startAudioLevelMonitoring();

    } catch (e) {
      throw AudioRecordingException(
        'Failed to start recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<String> stopRecording() async {
    try {
      if (_recorder == null || !isRecording) {
        throw AudioRecordingException('No active recording to stop');
      }

      // Stop audio level monitoring
      _stopAudioLevelMonitoring();

      // Stop recording
      final recordingPath = await _recorder!.stopRecorder();
      
      _recordingStartTime = null;
      
      if (recordingPath == null || _currentRecordingPath == null) {
        throw AudioRecordingException('Failed to get recording file path');
      }

      // Verify file exists and has content
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        throw AudioRecordingException('Recording file was not created');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw AudioRecordingException('Recording file is empty');
      }

      final savedPath = _currentRecordingPath!;
      _currentRecordingPath = null;
      
      // Deactivate iOS audio session after recording
      await IOSAudioSessionService.deactivateSession();
      
      return savedPath;

    } catch (e) {
      _recordingStartTime = null;
      _currentRecordingPath = null;
      throw AudioRecordingException(
        'Failed to stop recording: ${e.toString()}',
        e,
      );
    }
  }

  /// Generate a unique file path for the recording
  Future<String> _generateRecordingPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      
      // Create recordings directory if it doesn't exist
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${recordingsDir.path}/recording_$timestamp.m4a';
    } catch (e) {
      throw AudioRecordingException(
        'Failed to generate recording path: ${e.toString()}',
        e,
      );
    }
  }

  /// Start monitoring audio levels during recording
  void _startAudioLevelMonitoring() {
    if (_recorder == null) return;

    // Subscribe to audio level updates
    _recorder!.onProgress!.listen(
      (RecordingDisposition disposition) {
        // Convert decibels to normalized level (0.0 to 1.0)
        double normalizedLevel = 0.0;
        
        if (disposition.decibels != null) {
          // Enhanced dB to linear conversion with better scaling
          final db = disposition.decibels!;
          
          // Use a more realistic dB range: -50 dB (quiet) to -10 dB (loud)
          // This provides better sensitivity for voice recording
          if (db > -50) {
            normalizedLevel = (db + 50) / 40; // Scale from -50dB to -10dB
            normalizedLevel = normalizedLevel.clamp(0.0, 1.0);
            
            // Apply slight smoothing to reduce jitter
            if (_lastNormalizedLevel != null) {
              normalizedLevel = (_lastNormalizedLevel! * 0.3) + (normalizedLevel * 0.7);
            }
            _lastNormalizedLevel = normalizedLevel;
          }
        }

        // Emit raw audio level
        _audioLevelController?.add(normalizedLevel);

        // Analyze audio quality and emit quality metrics
        final qualityResult = _qualityAnalyzer.analyzeLevel(normalizedLevel);
        _audioQualityController?.add(qualityResult);
      },
      onError: (error) {
        // Handle audio level monitoring errors gracefully
        print('Audio level monitoring error: $error');
        _audioLevelController?.add(0.0);
        
        // Emit poor quality result on error
        final errorQuality = AudioQualityResult(
          quality: AudioQuality.poor,
          noiseLevel: NoiseLevel.veryNoisy,
          signalToNoiseRatio: 0.0,
          averageLevel: 0.0,
          isSpeechDetected: false,
          noiseReductionRecommended: true,
          confidenceScore: 0.0,
        );
        _audioQualityController?.add(errorQuality);
      },
    );
  }

  /// Stop monitoring audio levels
  void _stopAudioLevelMonitoring() {
    // Audio level monitoring stops automatically when recording stops
    // Just emit a final zero level and quality result
    _audioLevelController?.add(0.0);
    
    final finalQuality = AudioQualityResult(
      quality: AudioQuality.fair,
      noiseLevel: NoiseLevel.quiet,
      signalToNoiseRatio: 0.0,
      averageLevel: 0.0,
      isSpeechDetected: false,
      noiseReductionRecommended: false,
      confidenceScore: 0.5,
    );
    _audioQualityController?.add(finalQuality);
  }

  @override
  Future<void> dispose() async {
    try {
      // Stop any active recording
      if (isRecording) {
        await _recorder?.stopRecorder();
      }

      // Stop audio level monitoring
      _stopAudioLevelMonitoring();

      // Close the recorder
      await _recorder?.closeRecorder();
      
      // Close the streams
      await _audioLevelController?.close();
      await _audioQualityController?.close();

      // Cancel any active timers
      _recordingTimer?.cancel();

      // Reset state
      _recorder = null;
      _audioLevelController = null;
      _audioQualityController = null;
      _recordingTimer = null;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      _lastNormalizedLevel = null;
      _isInitialized = false;
      _qualityAnalyzer.reset();

    } catch (e) {
      // Log error but don't throw during disposal
      print('Error during AudioRecordingService disposal: $e');
    }
  }
}