import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_recording_service.dart';
import '../services/keyword_detection/keyword_detection_service.dart';
import '../services/storage/recording_manager_service.dart';
import '../services/background/simple_foreground_service.dart';
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
  final SimpleForegroundService _foregroundService = SimpleForegroundService();

  Timer? _autoStopTimer;
  Timer? _countdownTimer;
  StreamSubscription? _keywordDetectionSubscription;

  static const Duration _autoRecordingDuration = Duration(minutes: 10);

  SimpleKeywordRecorderNotifier(
    this._audioService,
    this._keywordService,
    this._recordingManager,
  ) : super(const SimpleKeywordRecorderState()) {
    // Initialize foreground service on creation (non-blocking, errors ignored)
    _foregroundService.initialize().catchError((error) {
      if (kDebugMode) debugPrint('Warning: Failed to initialize foreground service: $error');
    });
  }

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

      if (kDebugMode) debugPrint('Step 1: State updated');

      // Try to start foreground service (optional - don't fail if it doesn't work)
      try {
        if (kDebugMode) debugPrint('Step 2: Attempting to start foreground service...');
        final serviceStarted = await _foregroundService.start().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) debugPrint('Foreground service start timed out');
            return false;
          },
        );

        if (serviceStarted) {
          if (kDebugMode) debugPrint('Step 3: Foreground service started successfully');

          // Update notification only if service started
          try {
            await _foregroundService.updateNotification(
              title: 'Voice Keyword Recorder',
              content: 'Listening for your keyword...',
            );
            if (kDebugMode) debugPrint('Step 4: Notification updated');
          } catch (notifError) {
            if (kDebugMode) debugPrint('Warning: Failed to update notification: $notifError');
          }
        } else {
          if (kDebugMode) debugPrint('Step 3: Foreground service failed to start (continuing anyway)');
        }
      } catch (serviceError) {
        if (kDebugMode) debugPrint('Warning: Foreground service error (continuing anyway): $serviceError');
      }

      // Start keyword detection (this is critical)
      if (kDebugMode) debugPrint('Step 5: Starting keyword detection service...');
      await _keywordService.startListening();
      if (kDebugMode) debugPrint('Step 6: Keyword detection service started');

      // Listen for keyword detection
      if (kDebugMode) debugPrint('Step 7: Setting up keyword detection stream listener...');
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

      if (kDebugMode) debugPrint('Step 8: Successfully started listening!');
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

      // Try to stop foreground service if it was started
      try {
        await _foregroundService.stop();
      } catch (_) {
        // Ignore errors when stopping
      }
    }
  }

  /// Pause listening for the keyword
  Future<void> pauseListening() async {
    try {
      if (kDebugMode) debugPrint('=== PAUSE LISTENING ===');

      // Stop keyword detection
      try {
        if (kDebugMode) debugPrint('Stopping keyword detection...');
        await _keywordService.stopListening();
        if (kDebugMode) debugPrint('Keyword detection stopped');
      } catch (e) {
        if (kDebugMode) debugPrint('Error stopping keyword service: $e');
      }

      // Cancel stream subscription
      try {
        _keywordDetectionSubscription?.cancel();
        if (kDebugMode) debugPrint('Stream subscription cancelled');
      } catch (e) {
        if (kDebugMode) debugPrint('Error cancelling subscription: $e');
      }

      // Stop foreground service (optional - don't fail if it doesn't work)
      try {
        if (kDebugMode) debugPrint('Stopping foreground service...');
        await _foregroundService.stop();
        if (kDebugMode) debugPrint('Foreground service stopped');
      } catch (e) {
        if (kDebugMode) debugPrint('Warning: Failed to stop foreground service: $e');
      }

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

  /// Handle keyword detection - start 10-minute recording
  Future<void> _onKeywordDetected() async {
    try {
      if (kDebugMode) debugPrint('Keyword detected! Starting 10-minute recording...');

      state = state.copyWith(
        isAutoRecording: true,
        recordingTimeRemaining: _autoRecordingDuration,
        errorMessage: null,
      );

      // Update notification to show recording status
      await _foregroundService.updateNotification(
        title: 'Voice Keyword Recorder',
        content: 'Recording (10 min)...',
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

        final recordings = await _recordingManager.getRecordings();

        state = state.copyWith(
          isAutoRecording: false,
          recordingsCount: recordings.length,
          recordingTimeRemaining: null,
          errorMessage: null,
        );

        // Update notification back to listening status
        if (state.isListening) {
          await _foregroundService.updateNotification(
            title: 'Voice Keyword Recorder',
            content: 'Listening for your keyword...',
          );
        }

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
    _foregroundService.stop();
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
