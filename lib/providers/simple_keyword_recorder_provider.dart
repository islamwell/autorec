import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_recording_service.dart';
import '../services/keyword_detection/keyword_detection_service.dart';
import '../services/storage/recording_manager_service.dart';
import '../services/service_locator.dart';

/// Simple state for keyword recorder
class SimpleKeywordRecorderState {
  final bool hasKeyword;
  final bool isRecordingKeyword;
  final bool isListening;
  final bool isAutoRecording;
  final int recordingsCount;
  final String? errorMessage;
  final Duration? recordingTimeRemaining;

  const SimpleKeywordRecorderState({
    this.hasKeyword = false,
    this.isRecordingKeyword = false,
    this.isListening = false,
    this.isAutoRecording = false,
    this.recordingsCount = 0,
    this.errorMessage,
    this.recordingTimeRemaining,
  });

  SimpleKeywordRecorderState copyWith({
    bool? hasKeyword,
    bool? isRecordingKeyword,
    bool? isListening,
    bool? isAutoRecording,
    int? recordingsCount,
    String? errorMessage,
    Duration? recordingTimeRemaining,
  }) {
    return SimpleKeywordRecorderState(
      hasKeyword: hasKeyword ?? this.hasKeyword,
      isRecordingKeyword: isRecordingKeyword ?? this.isRecordingKeyword,
      isListening: isListening ?? this.isListening,
      isAutoRecording: isAutoRecording ?? this.isAutoRecording,
      recordingsCount: recordingsCount ?? this.recordingsCount,
      errorMessage: errorMessage,
      recordingTimeRemaining: recordingTimeRemaining,
    );
  }
}

/// Simple provider for keyword recording functionality
class SimpleKeywordRecorderNotifier extends StateNotifier<SimpleKeywordRecorderState> {
  final AudioRecordingService _audioService;
  final KeywordDetectionService _keywordService;
  final RecordingManagerService _recordingManager;

  Timer? _autoStopTimer;
  Timer? _countdownTimer;
  StreamSubscription? _keywordDetectionSubscription;

  static const Duration _autoRecordingDuration = Duration(minutes: 10);

  SimpleKeywordRecorderNotifier(
    this._audioService,
    this._keywordService,
    this._recordingManager,
  ) : super(const SimpleKeywordRecorderState());

  /// Start recording a keyword
  Future<void> startKeywordRecording() async {
    try {
      state = state.copyWith(
        isRecordingKeyword: true,
        errorMessage: null,
      );

      await _audioService.startRecording();
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting keyword recording: $e');
      state = state.copyWith(
        isRecordingKeyword: false,
        errorMessage: 'Failed to start recording: ${e.toString()}',
      );
    }
  }

  /// Stop recording keyword and save it
  Future<void> stopKeywordRecording() async {
    try {
      final audioPath = await _audioService.stopRecording();

      if (audioPath != null) {
        // Train the keyword detection with this audio
        await _keywordService.trainKeyword(audioPath);

        state = state.copyWith(
          isRecordingKeyword: false,
          hasKeyword: true,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isRecordingKeyword: false,
          errorMessage: 'Failed to save keyword recording',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error stopping keyword recording: $e');
      state = state.copyWith(
        isRecordingKeyword: false,
        errorMessage: 'Failed to save keyword: ${e.toString()}',
      );
    }
  }

  /// Start listening for the keyword
  Future<void> startListening() async {
    try {
      state = state.copyWith(
        isListening: true,
        errorMessage: null,
      );

      // Start keyword detection
      await _keywordService.startListening();

      // Listen for keyword detection
      _keywordDetectionSubscription?.cancel();
      _keywordDetectionSubscription = _keywordService.keywordDetectedStream.listen((detected) {
        if (detected && state.isListening && !state.isAutoRecording) {
          _onKeywordDetected();
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting listening: $e');
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Failed to start listening: ${e.toString()}',
      );
    }
  }

  /// Pause listening for the keyword
  Future<void> pauseListening() async {
    try {
      await _keywordService.stopListening();
      _keywordDetectionSubscription?.cancel();

      state = state.copyWith(
        isListening: false,
        errorMessage: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error pausing listening: $e');
      state = state.copyWith(
        errorMessage: 'Failed to pause listening: ${e.toString()}',
      );
    }
  }

  /// Handle keyword detection - start 10-minute recording
  Future<void> _onKeywordDetected() async {
    try {
      if (kDebugMode) debugPrint('Keyword detected! Starting 10-minute recording...');

      state = state.copyWith(
        isAutoRecording: true,
        recordingTimeRemaining: _autoRecordingDuration,
        errorMessage: null,
      );

      // Start recording
      await _audioService.startRecording();

      // Start countdown timer
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = _autoRecordingDuration - Duration(seconds: timer.tick);
        if (remaining.isNegative) {
          timer.cancel();
        } else {
          state = state.copyWith(recordingTimeRemaining: remaining);
        }
      });

      // Set auto-stop timer for 10 minutes
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(_autoRecordingDuration, () {
        _stopAutoRecording();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting auto-recording: $e');
      state = state.copyWith(
        isAutoRecording: false,
        errorMessage: 'Failed to start recording: ${e.toString()}',
      );
    }
  }

  /// Stop the 10-minute auto-recording and save it
  Future<void> _stopAutoRecording() async {
    try {
      _autoStopTimer?.cancel();
      _countdownTimer?.cancel();

      final audioPath = await _audioService.stopRecording();

      if (audioPath != null) {
        // Save the recording
        await _recordingManager.createRecording(
          audioPath,
          {
            'title': 'Auto-recorded',
            'description': 'Triggered by keyword at ${DateTime.now().toString()}',
            'isKeywordTriggered': true,
          },
        );

        final recordings = await _recordingManager.getAllRecordings();

        state = state.copyWith(
          isAutoRecording: false,
          recordingsCount: recordings.length,
          recordingTimeRemaining: null,
          errorMessage: null,
        );

        if (kDebugMode) debugPrint('Auto-recording saved successfully');
      } else {
        state = state.copyWith(
          isAutoRecording: false,
          recordingTimeRemaining: null,
          errorMessage: 'Failed to save recording',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error stopping auto-recording: $e');
      state = state.copyWith(
        isAutoRecording: false,
        recordingTimeRemaining: null,
        errorMessage: 'Failed to save recording: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();
    _keywordDetectionSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for simple keyword recorder
final simpleKeywordRecorderProvider =
    StateNotifierProvider<SimpleKeywordRecorderNotifier, SimpleKeywordRecorderState>((ref) {
  final audioService = ref.read(audioRecordingServiceProvider);
  final keywordService = ref.read(keywordDetectionServiceProvider);
  final recordingManager = ref.read(recordingManagerServiceProvider);

  return SimpleKeywordRecorderNotifier(
    audioService,
    keywordService,
    recordingManager,
  );
});
