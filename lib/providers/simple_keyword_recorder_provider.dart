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
      if (kDebugMode) debugPrint('=== START LISTENING ===');

      state = state.copyWith(
        isListening: true,
        errorMessage: null,
      );

      // Start keyword detection
      if (kDebugMode) debugPrint('Starting keyword detection service...');
      await _keywordService.startListening();
      if (kDebugMode) debugPrint('Keyword detection service started');

      // Listen for keyword detection
      if (kDebugMode) debugPrint('Setting up keyword detection stream listener...');
      _keywordDetectionSubscription?.cancel();
      _keywordDetectionSubscription = _keywordService.keywordDetectedStream.listen(
        (detected) {
          if (kDebugMode) debugPrint('Keyword detected: $detected');
          if (detected && state.isListening && !state.isAutoRecording) {
            _onKeywordDetected();
          }
        },
        onError: (error) {
          if (kDebugMode) debugPrint('Error in keyword detection stream: $error');
        },
      );

      if (kDebugMode) debugPrint('=== LISTENING STARTED ===');

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('!!! ERROR STARTING LISTENING !!!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      state = state.copyWith(
        isListening: false,
        errorMessage: 'Failed to start listening: ${e.toString()}',
      );
    }
  }

  /// Pause listening for the keyword
  Future<void> pauseListening() async {
    try {
      if (kDebugMode) debugPrint('=== PAUSE LISTENING ===');

      // Stop keyword detection
      await _keywordService.stopListening();
      _keywordDetectionSubscription?.cancel();

      state = state.copyWith(
        isListening: false,
        errorMessage: null,
      );

      if (kDebugMode) debugPrint('=== LISTENING PAUSED ===');

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('!!! ERROR PAUSING LISTENING !!!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Failed to pause listening: ${e.toString()}',
      );
    }
  }

  /// Start manual recording for testing
  Future<void> startManualRecording() async {
    try {
      if (kDebugMode) debugPrint('🧪 [MANUAL] Starting manual test recording...');

      state = state.copyWith(
        isAutoRecording: true,
        recordingTimeRemaining: _autoRecordingDuration,
        errorMessage: null,
      );

      // Start recording
      await _audioService.startRecording();

      if (kDebugMode) debugPrint('🧪 [MANUAL] Manual recording started!');

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
        stopManualRecording();
      });

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [MANUAL] Error starting manual recording: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = state.copyWith(
        isAutoRecording: false,
        errorMessage: 'Failed to start manual recording: ${e.toString()}',
      );
    }
  }

  /// Stop manual recording
  Future<void> stopManualRecording() async {
    try {
      if (kDebugMode) debugPrint('🧪 [MANUAL] Stopping manual recording...');

      _autoStopTimer?.cancel();
      _countdownTimer?.cancel();

      final audioPath = await _audioService.stopRecording();

      if (audioPath != null) {
        if (kDebugMode) debugPrint('🧪 [MANUAL] Recording stopped. Saving...');

        final duration = _autoRecordingDuration - (state.recordingTimeRemaining ?? Duration.zero);

        // Save the recording with proper metadata format
        await _recordingManager.createRecording(
          audioPath,
          {
            'keyword': 'Manual Test',
            'duration': duration.inMilliseconds,
            'quality': 'high',
            'compress': false, // Save as original format for testing
          },
        );

        final recordings = await _recordingManager.getRecordings();

        state = state.copyWith(
          isAutoRecording: false,
          recordingsCount: recordings.length,
          recordingTimeRemaining: null,
          errorMessage: null,
        );

        if (kDebugMode) debugPrint('✅ [MANUAL] Manual recording saved! Total: ${recordings.length}');
      } else {
        state = state.copyWith(
          isAutoRecording: false,
          recordingTimeRemaining: null,
          errorMessage: 'Failed to save manual recording',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [MANUAL] Error stopping manual recording: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = state.copyWith(
        isAutoRecording: false,
        recordingTimeRemaining: null,
        errorMessage: 'Failed to save manual recording: ${e.toString()}',
      );
    }
  }

  /// Handle keyword detection - start 10-minute recording
  Future<void> _onKeywordDetected() async {
    try {
      if (kDebugMode) debugPrint('=== KEYWORD DETECTED! ===');
      if (kDebugMode) debugPrint('Stopping keyword listening to start main recording...');

      // IMPORTANT: Stop keyword detection listening first to free up the microphone
      // The keyword detection service is actively recording for pattern matching,
      // so we need to stop it before starting the main recording
      await _keywordService.stopListening();
      _keywordDetectionSubscription?.cancel();

      if (kDebugMode) debugPrint('Keyword listening stopped. Starting 10-minute recording...');

      state = state.copyWith(
        isListening: false, // Update state to reflect that we're no longer listening for keywords
        isAutoRecording: true,
        recordingTimeRemaining: _autoRecordingDuration,
        errorMessage: null,
      );

      // Start the main recording
      await _audioService.startRecording();

      if (kDebugMode) debugPrint('Main recording started successfully!');

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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('!!! ERROR STARTING AUTO-RECORDING !!!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = state.copyWith(
        isAutoRecording: false,
        isListening: false,
        errorMessage: 'Failed to start recording: ${e.toString()}',
      );
    }
  }

  /// Stop the 10-minute auto-recording and save it
  Future<void> _stopAutoRecording() async {
    try {
      if (kDebugMode) debugPrint('=== STOPPING AUTO-RECORDING ===');

      _autoStopTimer?.cancel();
      _countdownTimer?.cancel();

      final audioPath = await _audioService.stopRecording();

      if (audioPath != null) {
        if (kDebugMode) debugPrint('Recording stopped. Saving recording...');

        final duration = _autoRecordingDuration - (state.recordingTimeRemaining ?? Duration.zero);

        // Save the recording with proper metadata format
        await _recordingManager.createRecording(
          audioPath,
          {
            'keyword': 'Keyword Triggered',
            'duration': duration.inMilliseconds,
            'quality': 'high',
            'compress': true, // Compress auto-recordings to save space
          },
        );

        final recordings = await _recordingManager.getRecordings();

        state = state.copyWith(
          isAutoRecording: false,
          recordingsCount: recordings.length,
          recordingTimeRemaining: null,
          errorMessage: null,
        );

        if (kDebugMode) debugPrint('Auto-recording saved successfully! Total recordings: ${recordings.length}');

        // Optionally restart keyword listening after recording finishes
        // This allows continuous keyword detection for multiple recordings
        if (kDebugMode) debugPrint('Restarting keyword listening for continuous detection...');
        await startListening();

      } else {
        state = state.copyWith(
          isAutoRecording: false,
          recordingTimeRemaining: null,
          errorMessage: 'Failed to save recording',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('!!! ERROR STOPPING AUTO-RECORDING !!!');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
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
