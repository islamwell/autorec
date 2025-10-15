import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/state/state_persistence_service.dart';

import '../models/app_settings.dart';
import '../models/recording.dart';
import '../models/keyword_profile.dart';

/// Global app state that combines all major state components
class AppState {
  final bool isInitialized;
  final bool hasRequiredPermissions;
  final AppSettings settings;
  final List<Recording> recordings;
  final KeywordProfile? activeKeywordProfile;
  final bool isRecording;
  final bool isKeywordListening;
  final String? lastError;

  const AppState({
    this.isInitialized = false,
    this.hasRequiredPermissions = false,
    required this.settings,
    this.recordings = const [],
    this.activeKeywordProfile,
    this.isRecording = false,
    this.isKeywordListening = false,
    this.lastError,
  });

  AppState copyWith({
    bool? isInitialized,
    bool? hasRequiredPermissions,
    AppSettings? settings,
    List<Recording>? recordings,
    KeywordProfile? activeKeywordProfile,
    bool? isRecording,
    bool? isKeywordListening,
    String? lastError,
  }) {
    return AppState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasRequiredPermissions: hasRequiredPermissions ?? this.hasRequiredPermissions,
      settings: settings ?? this.settings,
      recordings: recordings ?? this.recordings,
      activeKeywordProfile: activeKeywordProfile ?? this.activeKeywordProfile,
      isRecording: isRecording ?? this.isRecording,
      isKeywordListening: isKeywordListening ?? this.isKeywordListening,
      lastError: lastError,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'isInitialized': isInitialized,
      'hasRequiredPermissions': hasRequiredPermissions,
      'settings': settings.toJson(),
      'recordings': recordings.map((r) => r.toJson()).toList(),
      'activeKeywordProfile': activeKeywordProfile?.toJson(),
      'isRecording': isRecording,
      'isKeywordListening': isKeywordListening,
      'lastError': lastError,
    };
  }

  /// Create from JSON for restoration
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      isInitialized: json['isInitialized'] ?? false,
      hasRequiredPermissions: json['hasRequiredPermissions'] ?? false,
      settings: AppSettings.fromJson(json['settings'] ?? {}),
      recordings: (json['recordings'] as List<dynamic>?)
          ?.map((r) => Recording.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      activeKeywordProfile: json['activeKeywordProfile'] != null
          ? KeywordProfile.fromJson(json['activeKeywordProfile'] as Map<String, dynamic>)
          : null,
      isRecording: json['isRecording'] ?? false,
      isKeywordListening: json['isKeywordListening'] ?? false,
      lastError: json['lastError'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.isInitialized == isInitialized &&
        other.hasRequiredPermissions == hasRequiredPermissions &&
        other.settings == settings &&
        other.recordings.length == recordings.length &&
        other.activeKeywordProfile == activeKeywordProfile &&
        other.isRecording == isRecording &&
        other.isKeywordListening == isKeywordListening &&
        other.lastError == lastError;
  }

  @override
  int get hashCode {
    return Object.hash(
      isInitialized,
      hasRequiredPermissions,
      settings,
      recordings.length,
      activeKeywordProfile,
      isRecording,
      isKeywordListening,
      lastError,
    );
  }
}

/// Notifier for managing global app state
class AppStateNotifier extends StateNotifier<AppState> {
  static const String _appStateKey = 'global_app_state';
  final StatePersistenceService _persistenceService;

  AppStateNotifier(this._persistenceService) 
      : super(AppState(settings: AppSettings.defaultSettings())) {
    _initializeState();
  }

  /// Initialize app state from persistence or defaults
  Future<void> _initializeState() async {
    try {
      final persistedState = await _persistenceService.loadState(_appStateKey);
      
      if (persistedState != null) {
        try {
          final restoredState = AppState.fromJson(persistedState);
          state = restoredState.copyWith(
            // Reset runtime state that shouldn't persist
            isRecording: false,
            lastError: null,
          );
        } catch (e) {
          // If restoration fails, use defaults but log the error
          state = state.copyWith(
            lastError: 'Failed to restore previous state: ${e.toString()}',
          );
        }
      }
      
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        lastError: 'Failed to initialize app state: ${e.toString()}',
      );
    }
  }

  /// Persist current state
  Future<void> _persistState() async {
    try {
      await _persistenceService.saveState(_appStateKey, state.toJson());
    } catch (e) {
      // Don't update state on persistence failure, just log
      print('Failed to persist app state: $e');
    }
  }

  /// Update permissions status
  void updatePermissionsStatus(bool hasPermissions) {
    state = state.copyWith(hasRequiredPermissions: hasPermissions);
    _persistState();
  }

  /// Update app settings
  void updateSettings(AppSettings settings) {
    state = state.copyWith(settings: settings);
    _persistState();
  }

  /// Update recordings list
  void updateRecordings(List<Recording> recordings) {
    state = state.copyWith(recordings: recordings);
    _persistState();
  }

  /// Update active keyword profile
  void updateActiveKeywordProfile(KeywordProfile? profile) {
    state = state.copyWith(activeKeywordProfile: profile);
    _persistState();
  }

  /// Update recording status
  void updateRecordingStatus(bool isRecording) {
    state = state.copyWith(isRecording: isRecording);
    // Don't persist recording status as it's runtime state
  }

  /// Update keyword listening status
  void updateKeywordListeningStatus(bool isListening) {
    state = state.copyWith(isKeywordListening: isListening);
    // Don't persist listening status as it's runtime state
  }

  /// Set error message
  void setError(String error) {
    state = state.copyWith(lastError: error);
    // Don't persist errors
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(lastError: null);
  }

  /// Reset app state to defaults
  Future<void> resetToDefaults() async {
    try {
      await _persistenceService.removeState(_appStateKey);
      state = AppState(
        isInitialized: true,
        settings: AppSettings.defaultSettings(),
      );
    } catch (e) {
      state = state.copyWith(
        lastError: 'Failed to reset app state: ${e.toString()}',
      );
    }
  }

  /// Get state summary for debugging
  Map<String, dynamic> getStateSummary() {
    return {
      'isInitialized': state.isInitialized,
      'hasRequiredPermissions': state.hasRequiredPermissions,
      'recordingsCount': state.recordings.length,
      'hasActiveKeywordProfile': state.activeKeywordProfile != null,
      'isRecording': state.isRecording,
      'isKeywordListening': state.isKeywordListening,
      'hasError': state.lastError != null,
    };
  }
}

/// Provider for state persistence service
final statePersistenceServiceProvider = Provider<StatePersistenceService>((ref) {
  return StatePersistenceServiceImpl();
});

/// Provider for global app state
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final persistenceService = ref.read(statePersistenceServiceProvider);
  return AppStateNotifier(persistenceService);
});

/// Convenience providers for specific aspects of app state
final appInitializedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isInitialized;
});

final appPermissionsStatusProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).hasRequiredPermissions;
});

final appErrorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).lastError;
});

final appRecordingStatusProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isRecording;
});

final appKeywordListeningStatusProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isKeywordListening;
});