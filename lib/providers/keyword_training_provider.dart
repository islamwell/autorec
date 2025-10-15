import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/keyword_profile.dart';
import '../services/service_locator.dart';
import '../services/keyword_detection/keyword_training_service.dart';

/// State for keyword training process
class KeywordTrainingState {
  final bool isRecording;
  final Duration recordingDuration;
  final double audioLevel;
  final String? errorMessage;
  final KeywordProfile? trainedProfile;
  final bool isProcessing;

  const KeywordTrainingState({
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.audioLevel = 0.0,
    this.errorMessage,
    this.trainedProfile,
    this.isProcessing = false,
  });

  KeywordTrainingState copyWith({
    bool? isRecording,
    Duration? recordingDuration,
    double? audioLevel,
    String? errorMessage,
    KeywordProfile? trainedProfile,
    bool? isProcessing,
  }) {
    return KeywordTrainingState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      audioLevel: audioLevel ?? this.audioLevel,
      errorMessage: errorMessage,
      trainedProfile: trainedProfile ?? this.trainedProfile,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Clear error message
  KeywordTrainingState clearError() {
    return copyWith(errorMessage: null);
  }

  /// Reset to initial state
  KeywordTrainingState reset() {
    return const KeywordTrainingState();
  }
}

/// Provider for keyword training functionality
class KeywordTrainingNotifier extends StateNotifier<KeywordTrainingState> {
  final KeywordTrainingService _trainingService;
  StreamSubscription<double>? _audioLevelSubscription;
  Timer? _durationTimer;

  KeywordTrainingNotifier(this._trainingService) : super(const KeywordTrainingState());

  /// Start recording a keyword for training
  Future<void> startRecording() async {
    if (state.isRecording || state.isProcessing) {
      return;
    }

    try {
      state = state.clearError();
      
      await _trainingService.startKeywordRecording();
      
      // Subscribe to audio levels
      _audioLevelSubscription = _trainingService.audioLevelStream.listen(
        (level) {
          if (mounted) {
            state = state.copyWith(audioLevel: level);
          }
        },
        onError: (error) {
          if (mounted) {
            state = state.copyWith(errorMessage: 'Audio monitoring error: $error');
          }
        },
      );
      
      // Start duration timer
      _startDurationTimer();
      
      state = state.copyWith(isRecording: true);
      
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start recording: ${e.toString()}',
        isRecording: false,
      );
    }
  }

  /// Stop recording and process the keyword
  Future<void> stopAndProcessKeyword(String keywordText) async {
    if (!state.isRecording || state.isProcessing) {
      return;
    }

    try {
      state = state.copyWith(isProcessing: true);
      
      // Stop timers and subscriptions
      await _stopMonitoring();
      
      // Process the keyword
      final profile = await _trainingService.stopAndProcessKeyword(keywordText);
      
      state = state.copyWith(
        isRecording: false,
        isProcessing: false,
        trainedProfile: profile,
        recordingDuration: Duration.zero,
        audioLevel: 0.0,
      );
      
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        isProcessing: false,
        errorMessage: 'Failed to process keyword: ${e.toString()}',
      );
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    if (!state.isRecording && !state.isProcessing) {
      return;
    }

    try {
      await _stopMonitoring();
      await _trainingService.cancelRecording();
      
      state = state.copyWith(
        isRecording: false,
        isProcessing: false,
        recordingDuration: Duration.zero,
        audioLevel: 0.0,
      );
      
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to cancel recording: ${e.toString()}',
        isRecording: false,
        isProcessing: false,
      );
    }
  }

  /// Validate keyword text
  KeywordValidationResult validateKeyword(String keywordText) {
    return _trainingService.validateKeyword(keywordText);
  }

  /// Clear any error messages
  void clearError() {
    state = state.clearError();
  }

  /// Reset the training state
  void reset() {
    state = state.reset();
  }

  /// Start the duration timer
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && state.isRecording) {
        final duration = _trainingService.recordingDuration;
        state = state.copyWith(recordingDuration: duration);
      }
    });
  }

  /// Stop monitoring (timers and subscriptions)
  Future<void> _stopMonitoring() async {
    await _audioLevelSubscription?.cancel();
    _audioLevelSubscription = null;
    
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  void dispose() {
    _stopMonitoring();
    _trainingService.dispose();
    super.dispose();
  }
}

/// Provider for keyword training state
final keywordTrainingProvider = StateNotifierProvider<KeywordTrainingNotifier, KeywordTrainingState>((ref) {
  final trainingService = ref.read(keywordTrainingServiceProvider);
  return KeywordTrainingNotifier(trainingService);
});

/// Provider for checking if keyword training is available
final keywordTrainingAvailableProvider = Provider<bool>((ref) {
  try {
    ref.read(keywordTrainingServiceProvider);
    return true;
  } catch (e) {
    return false;
  }
});