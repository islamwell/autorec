import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_recording_service.dart';
import '../services/audio/audio_quality_analyzer.dart';
import '../services/timer/auto_stop_timer_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/service_locator.dart';

import 'dart:async';

/// State class for recording functionality
class RecordingState {
  final bool isRecording;
  final Duration recordingDuration;
  final double audioLevel;
  final AudioQualityResult? audioQuality;
  final String? errorMessage;
  final String? currentRecordingPath;
  final bool isInitialized;
  final bool isAutoStopTimerActive;
  final Duration autoStopRemainingTime;

  const RecordingState({
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.audioLevel = 0.0,
    this.audioQuality,
    this.errorMessage,
    this.currentRecordingPath,
    this.isInitialized = false,
    this.isAutoStopTimerActive = false,
    this.autoStopRemainingTime = Duration.zero,
  });

  RecordingState copyWith({
    bool? isRecording,
    Duration? recordingDuration,
    double? audioLevel,
    AudioQualityResult? audioQuality,
    String? errorMessage,
    String? currentRecordingPath,
    bool? isInitialized,
    bool? isAutoStopTimerActive,
    Duration? autoStopRemainingTime,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      audioLevel: audioLevel ?? this.audioLevel,
      audioQuality: audioQuality ?? this.audioQuality,
      errorMessage: errorMessage ?? this.errorMessage,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      isInitialized: isInitialized ?? this.isInitialized,
      isAutoStopTimerActive: isAutoStopTimerActive ?? this.isAutoStopTimerActive,
      autoStopRemainingTime: autoStopRemainingTime ?? this.autoStopRemainingTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordingState &&
        other.isRecording == isRecording &&
        other.recordingDuration == recordingDuration &&
        other.audioLevel == audioLevel &&
        other.audioQuality == audioQuality &&
        other.errorMessage == errorMessage &&
        other.currentRecordingPath == currentRecordingPath &&
        other.isInitialized == isInitialized &&
        other.isAutoStopTimerActive == isAutoStopTimerActive &&
        other.autoStopRemainingTime == autoStopRemainingTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      isRecording,
      recordingDuration,
      audioLevel,
      audioQuality,
      errorMessage,
      currentRecordingPath,
      isInitialized,
      isAutoStopTimerActive,
      autoStopRemainingTime,
    );
  }
}

/// Provider for managing recording state and operations
class RecordingNotifier extends StateNotifier<RecordingState> {
  final AudioRecordingService _audioService;
  final AutoStopTimerService _timerService;
  final NotificationService _notificationService;
  StreamSubscription<Duration>? _timerSubscription;
  StreamSubscription<void>? _timerCompleteSubscription;
  bool _hasInitialized = false;

  // SOLUTION 3: Lazy initialization - don't initialize until actually needed
  RecordingNotifier(this._audioService, this._timerService, this._notificationService) : super(const RecordingState());

  /// Initialize the recording provider (called lazily)
  Future<void> _initialize() async {
    if (_hasInitialized) return; // Already initialized
    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Configure audio service for voice recording
      await _audioService.configureForVoice();
      
      // Listen to audio level changes
      _audioService.audioLevelStream.listen((level) {
        state = state.copyWith(audioLevel: level);
      });

      // Listen to audio quality changes
      _audioService.audioQualityStream.listen((quality) {
        state = state.copyWith(audioQuality: quality);
      });

      state = state.copyWith(isInitialized: true);
      _hasInitialized = true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to initialize recording: ${e.toString()}',
      );
    }
  }

  /// Start recording with optional auto-stop duration
  Future<void> startRecording([Duration? autoStopDuration]) async {
    if (state.isRecording) return;

    // Initialize on first use (lazy)
    await _initialize();

    try {
      state = state.copyWith(errorMessage: null);
      
      await _audioService.startRecording();
      
      state = state.copyWith(
        isRecording: true,
        recordingDuration: Duration.zero,
      );

      // Start duration tracking
      _startDurationTracking();

      // Start auto-stop timer if duration is provided
      if (autoStopDuration != null) {
        _startAutoStopTimer(autoStopDuration);
      }

      // Show recording started notification
      try {
        await _notificationService.showRecordingStartedNotification();
      } catch (e) {
        // Don't fail recording if notification fails
        print('Failed to show recording started notification: $e');
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isRecording: false,
      );
      rethrow;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    if (!state.isRecording) return null;

    try {
      // Stop auto-stop timer if active
      _stopAutoStopTimer();

      final recordingPath = await _audioService.stopRecording();
      final recordingDuration = state.recordingDuration;
      
      state = state.copyWith(
        isRecording: false,
        currentRecordingPath: recordingPath,
        audioLevel: 0.0,
        isAutoStopTimerActive: false,
        autoStopRemainingTime: Duration.zero,
      );

      // Show recording stopped notification
      try {
        await _notificationService.showRecordingStoppedNotification(
          recordingDuration: recordingDuration,
        );
      } catch (e) {
        // Don't fail recording if notification fails
        print('Failed to show recording stopped notification: $e');
      }

      return recordingPath;
    } catch (e) {
      // Stop timer even on error
      _stopAutoStopTimer();
      
      state = state.copyWith(
        errorMessage: e.toString(),
        isRecording: false,
        isAutoStopTimerActive: false,
        autoStopRemainingTime: Duration.zero,
      );
      rethrow;
    }
  }

  /// Start tracking recording duration
  void _startDurationTracking() {
    if (!state.isRecording) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (state.isRecording) {
        state = state.copyWith(
          recordingDuration: Duration(
            seconds: state.recordingDuration.inSeconds + 1,
          ),
        );
        _startDurationTracking();
      }
    });
  }

  /// Start auto-stop timer
  void _startAutoStopTimer(Duration duration) {
    try {
      // Stop any existing timer
      _stopAutoStopTimer();

      // Start new timer
      _timerSubscription = _timerService.startTimer(duration).listen(
        (remainingTime) {
          state = state.copyWith(
            isAutoStopTimerActive: true,
            autoStopRemainingTime: remainingTime,
          );
        },
        onError: (error) {
          state = state.copyWith(
            errorMessage: 'Auto-stop timer error: ${error.toString()}',
            isAutoStopTimerActive: false,
            autoStopRemainingTime: Duration.zero,
          );
        },
      );

      // Listen for timer completion
      _timerCompleteSubscription = _timerService.onTimerComplete.listen((_) {
        // Auto-stop the recording when timer completes
        _handleAutoStopTimerComplete();
      });

    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start auto-stop timer: ${e.toString()}',
        isAutoStopTimerActive: false,
        autoStopRemainingTime: Duration.zero,
      );
    }
  }

  /// Stop auto-stop timer
  void _stopAutoStopTimer() {
    _timerSubscription?.cancel();
    _timerSubscription = null;
    _timerCompleteSubscription?.cancel();
    _timerCompleteSubscription = null;
    _timerService.stopTimer();
    
    state = state.copyWith(
      isAutoStopTimerActive: false,
      autoStopRemainingTime: Duration.zero,
    );
  }

  /// Handle auto-stop timer completion
  Future<void> _handleAutoStopTimerComplete() async {
    if (!state.isRecording) return;

    try {
      // Stop the recording automatically
      final recordingPath = await stopRecording();
      
      // Show auto-stop notification
      if (recordingPath != null) {
        try {
          await _notificationService.showAutoStopNotification(
            recordingPath: recordingPath,
            recordingDuration: state.recordingDuration,
          );
        } catch (e) {
          // Don't fail if notification fails
          print('Failed to show auto-stop notification: $e');
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Auto-stop failed: ${e.toString()}',
        isRecording: false,
        isAutoStopTimerActive: false,
        autoStopRemainingTime: Duration.zero,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get current audio quality
  AudioQualityResult? get currentAudioQuality => _audioService.currentAudioQuality;

  @override
  void dispose() {
    _stopAutoStopTimer();
    _timerService.dispose();
    _notificationService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

/// Provider for recording state
final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  final audioService = ref.read(audioRecordingServiceProvider);
  final timerService = ref.read(autoStopTimerServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  return RecordingNotifier(audioService, timerService, notificationService);
});

/// Provider for checking if recording is active
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(recordingProvider).isRecording;
});

/// Provider for current audio level
final audioLevelProvider = Provider<double>((ref) {
  return ref.watch(recordingProvider).audioLevel;
});

/// Provider for current audio quality
final audioQualityProvider = Provider<AudioQualityResult?>((ref) {
  return ref.watch(recordingProvider).audioQuality;
});

/// Provider for recording duration
final recordingDurationProvider = Provider<Duration>((ref) {
  return ref.watch(recordingProvider).recordingDuration;
});

/// Provider for auto-stop timer active state
final autoStopTimerActiveProvider = Provider<bool>((ref) {
  return ref.watch(recordingProvider).isAutoStopTimerActive;
});

/// Provider for auto-stop timer remaining time
final autoStopRemainingTimeProvider = Provider<Duration>((ref) {
  return ref.watch(recordingProvider).autoStopRemainingTime;
});