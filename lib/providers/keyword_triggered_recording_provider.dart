import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/keyword_detection/keyword_detection_service.dart';
import '../services/storage/file_storage_service.dart';
import '../services/service_locator.dart';
import '../models/keyword_profile.dart';
import 'recording_provider.dart';
import 'keyword_training_provider.dart';

/// State for keyword-triggered recording system
class KeywordTriggeredRecordingState {
  final bool isListening;
  final bool isAutoRecording;
  final KeywordProfile? activeProfile;
  final double confidenceLevel;
  final String? errorMessage;
  final int recordingsTriggered;
  final DateTime? lastDetectionTime;

  const KeywordTriggeredRecordingState({
    this.isListening = false,
    this.isAutoRecording = false,
    this.activeProfile,
    this.confidenceLevel = 0.0,
    this.errorMessage,
    this.recordingsTriggered = 0,
    this.lastDetectionTime,
  });

  KeywordTriggeredRecordingState copyWith({
    bool? isListening,
    bool? isAutoRecording,
    KeywordProfile? activeProfile,
    double? confidenceLevel,
    String? errorMessage,
    int? recordingsTriggered,
    DateTime? lastDetectionTime,
  }) {
    return KeywordTriggeredRecordingState(
      isListening: isListening ?? this.isListening,
      isAutoRecording: isAutoRecording ?? this.isAutoRecording,
      activeProfile: activeProfile ?? this.activeProfile,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      errorMessage: errorMessage,
      recordingsTriggered: recordingsTriggered ?? this.recordingsTriggered,
      lastDetectionTime: lastDetectionTime ?? this.lastDetectionTime,
    );
  }
}

/// Provider for keyword-triggered recording functionality
class KeywordTriggeredRecordingNotifier
    extends StateNotifier<KeywordTriggeredRecordingState> {
  final KeywordDetectionService _keywordService;
  final FileStorageService _storageService;
  final Ref _ref;

  StreamSubscription<bool>? _keywordDetectionSubscription;
  StreamSubscription<double>? _confidenceSubscription;

  // Configuration
  static const Duration _autoRecordingDuration = Duration(minutes: 10);
  static const Duration _cooldownPeriod = Duration(seconds: 30);

  KeywordTriggeredRecordingNotifier(
    this._keywordService,
    this._storageService,
    this._ref,
  ) : super(const KeywordTriggeredRecordingState());

  /// Start listening for keyword with the current trained profile
  Future<void> startListening() async {
    if (state.isListening) {
      return;
    }

    try {
      // Check if we have a trained keyword profile
      final keywordTrainingState = _ref.read(keywordTrainingProvider);
      final profile = keywordTrainingState.trainedProfile;

      if (profile == null) {
        throw Exception(
          'No trained keyword found. Please train a keyword first.',
        );
      }

      // Load the keyword profile into the detection service
      await _keywordService.loadProfile(profile);

      // Start keyword detection
      await _keywordService.startListening();

      // Subscribe to keyword detection events
      _keywordDetectionSubscription =
          _keywordService.keywordDetectedStream.listen(
        _onKeywordDetected,
        onError: _onKeywordDetectionError,
      );

      // Subscribe to confidence level updates
      _confidenceSubscription = _keywordService.confidenceStream.listen(
        (confidence) {
          state = state.copyWith(confidenceLevel: confidence);
        },
      );

      state = state.copyWith(
        isListening: true,
        activeProfile: profile,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start listening: ${e.toString()}',
        isListening: false,
      );
      rethrow;
    }
  }

  /// Stop listening for keyword
  Future<void> stopListening() async {
    if (!state.isListening) {
      return;
    }

    try {
      // Cancel subscriptions
      await _keywordDetectionSubscription?.cancel();
      await _confidenceSubscription?.cancel();
      _keywordDetectionSubscription = null;
      _confidenceSubscription = null;

      // Stop keyword detection service
      await _keywordService.stopListening();

      // If auto-recording is active, stop it
      if (state.isAutoRecording) {
        await _stopAutoRecording();
      }

      state = state.copyWith(
        isListening: false,
        confidenceLevel: 0.0,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop listening: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Handle keyword detection event
  void _onKeywordDetected(bool detected) {
    if (!detected || !state.isListening) {
      return;
    }

    // Check cooldown period
    if (state.lastDetectionTime != null) {
      final timeSinceLastDetection =
          DateTime.now().difference(state.lastDetectionTime!);
      if (timeSinceLastDetection < _cooldownPeriod) {
        debugPrint('Keyword detected but in cooldown period. Ignoring.');
        return;
      }
    }

    // Trigger automatic recording
    _triggerAutoRecording();
  }

  /// Trigger automatic recording when keyword is detected
  Future<void> _triggerAutoRecording() async {
    if (state.isAutoRecording) {
      debugPrint('Auto-recording already in progress. Ignoring new detection.');
      return;
    }

    try {
      state = state.copyWith(
        isAutoRecording: true,
        lastDetectionTime: DateTime.now(),
        recordingsTriggered: state.recordingsTriggered + 1,
      );

      // Start recording with 10-minute auto-stop timer
      final recordingNotifier = _ref.read(recordingProvider.notifier);
      await recordingNotifier.startRecording(_autoRecordingDuration);

      debugPrint('Keyword detected! Auto-recording started for $_autoRecordingDuration');
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start auto-recording: ${e.toString()}',
        isAutoRecording: false,
      );
      debugPrint('Auto-recording failed: $e');
    }
  }

  /// Stop auto-recording
  Future<void> _stopAutoRecording() async {
    if (!state.isAutoRecording) {
      return;
    }

    try {
      final recordingNotifier = _ref.read(recordingProvider.notifier);
      final recordingPath = await recordingNotifier.stopRecording();

      if (recordingPath != null) {
        // Save recording metadata
        await _saveRecordingMetadata(recordingPath);
      }

      state = state.copyWith(isAutoRecording: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop auto-recording: ${e.toString()}',
        isAutoRecording: false,
      );
      debugPrint('Failed to stop auto-recording: $e');
    }
  }

  /// Save recording metadata to storage
  Future<void> _saveRecordingMetadata(String recordingPath) async {
    try {
      final metadata = {
        'keyword': state.activeProfile?.keyword ?? 'unknown',
        'auto_triggered': true,
        'detection_time': state.lastDetectionTime?.toIso8601String(),
        'confidence': state.confidenceLevel,
      };

      await _storageService.saveRecording(recordingPath, metadata);
      debugPrint('Recording metadata saved successfully');
    } catch (e) {
      debugPrint('Failed to save recording metadata: $e');
      // Don't rethrow - metadata save failure shouldn't fail the whole operation
    }
  }

  /// Handle keyword detection errors
  void _onKeywordDetectionError(dynamic error) {
    state = state.copyWith(
      errorMessage: 'Keyword detection error: ${error.toString()}',
    );
    debugPrint('Keyword detection error: $error');
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get statistics about keyword-triggered recordings
  Map<String, dynamic> getStatistics() {
    return {
      'total_recordings_triggered': state.recordingsTriggered,
      'last_detection_time': state.lastDetectionTime?.toIso8601String(),
      'active_profile': state.activeProfile?.keyword,
      'is_listening': state.isListening,
      'is_auto_recording': state.isAutoRecording,
      'current_confidence': state.confidenceLevel,
    };
  }

  @override
  void dispose() {
    _keywordDetectionSubscription?.cancel();
    _confidenceSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for keyword-triggered recording state
final keywordTriggeredRecordingProvider = StateNotifierProvider<
    KeywordTriggeredRecordingNotifier, KeywordTriggeredRecordingState>((ref) {
  final keywordService = ref.read(keywordDetectionServiceProvider);
  final storageService = ref.read(fileStorageServiceProvider);
  return KeywordTriggeredRecordingNotifier(
    keywordService,
    storageService,
    ref,
  );
});

/// Provider for checking if keyword listening is active
final isKeywordListeningProvider = Provider<bool>((ref) {
  return ref.watch(keywordTriggeredRecordingProvider).isListening;
});

/// Provider for checking if auto-recording is active
final isAutoRecordingProvider = Provider<bool>((ref) {
  return ref.watch(keywordTriggeredRecordingProvider).isAutoRecording;
});

/// Provider for current confidence level
final keywordConfidenceProvider = Provider<double>((ref) {
  return ref.watch(keywordTriggeredRecordingProvider).confidenceLevel;
});

/// Provider for active keyword profile
final activeKeywordProfileProvider = Provider<KeywordProfile?>((ref) {
  return ref.watch(keywordTriggeredRecordingProvider).activeProfile;
});
