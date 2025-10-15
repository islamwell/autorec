import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state_provider.dart';
import 'settings_provider.dart';
import 'recordings_provider.dart';
import 'recording_provider.dart';
import 'permission_provider.dart';
import 'background_listening_provider.dart';

import '../services/permissions/permission_service.dart';

/// Provider that synchronizes state between global app state and individual providers
/// This ensures all providers stay in sync and state changes are properly propagated
final stateSynchronizationProvider = Provider<void>((ref) {
  // Watch all the individual providers and sync with global state
  _syncPermissions(ref);
  _syncSettings(ref);
  _syncRecordings(ref);
  _syncRecordingStatus(ref);
  _syncKeywordListening(ref);
});

/// Synchronize permission status with global app state
void _syncPermissions(Ref ref) {
  // Watch permission changes and update global state
  ref.listen<Map<AppPermission, PermissionStatus>>(
    permissionStatusProvider,
    (previous, next) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      final hasAllPermissions = next.values.every(
        (status) => status == PermissionStatus.granted,
      );
      appStateNotifier.updatePermissionsStatus(hasAllPermissions);
    },
  );

  // Also check the computed provider for required permissions
  ref.listen<AsyncValue<bool>>(
    hasAllRequiredPermissionsProvider,
    (previous, next) {
      next.whenData((hasPermissions) {
        final appStateNotifier = ref.read(appStateProvider.notifier);
        appStateNotifier.updatePermissionsStatus(hasPermissions);
      });
    },
  );
}

/// Synchronize settings with global app state
void _syncSettings(Ref ref) {
  ref.listen<SettingsState>(
    settingsProvider,
    (previous, next) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      appStateNotifier.updateSettings(next.settings);
      
      // Handle settings errors
      if (next.errorMessage != null) {
        appStateNotifier.setError('Settings error: ${next.errorMessage}');
      }
    },
  );
}

/// Synchronize recordings list with global app state
void _syncRecordings(Ref ref) {
  ref.listen<RecordingsState>(
    recordingsProvider,
    (previous, next) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      appStateNotifier.updateRecordings(next.recordings);
      
      // Handle recordings errors
      if (next.error != null) {
        appStateNotifier.setError('Recordings error: ${next.error}');
      }
    },
  );
}

/// Synchronize recording status with global app state
void _syncRecordingStatus(Ref ref) {
  ref.listen<RecordingState>(
    recordingProvider,
    (previous, next) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      appStateNotifier.updateRecordingStatus(next.isRecording);
      
      // Handle recording errors
      if (next.errorMessage != null) {
        appStateNotifier.setError('Recording error: ${next.errorMessage}');
      }
    },
  );
}

/// Synchronize keyword listening status with global app state
void _syncKeywordListening(Ref ref) {
  ref.listen<BackgroundListeningState>(
    backgroundListeningProvider,
    (previous, next) {
      final appStateNotifier = ref.read(appStateProvider.notifier);
      appStateNotifier.updateKeywordListeningStatus(next.isListening);
      
      // Handle background listening errors
      if (next.errorMessage != null) {
        appStateNotifier.setError('Background listening error: ${next.errorMessage}');
      }
    },
  );
}

/// Provider that watches for global app state changes and propagates them to individual providers
/// This ensures that when global state is restored, individual providers are updated
final stateRestorationProvider = Provider<void>((ref) {
  final appState = ref.watch(appStateProvider);
  
  // Only restore state after initialization
  if (!appState.isInitialized) return;
  
  // Restore settings if they differ from current provider state
  final currentSettings = ref.read(settingsProvider).settings;
  if (currentSettings != appState.settings) {
    Future.microtask(() {
      final settingsNotifier = ref.read(settingsProvider.notifier);
      // Update settings without triggering persistence (to avoid loops)
      settingsNotifier.state = settingsNotifier.state.copyWith(
        settings: appState.settings,
      );
    });
  }
  
  // Restore recordings if they differ from current provider state
  final currentRecordings = ref.read(recordingsProvider).recordings;
  if (currentRecordings.length != appState.recordings.length) {
    Future.microtask(() {
      final recordingsNotifier = ref.read(recordingsProvider.notifier);
      recordingsNotifier.state = recordingsNotifier.state.copyWith(
        recordings: appState.recordings,
      );
    });
  }
});

/// Provider that manages error state across the application
final errorManagementProvider = Provider<void>((ref) {
  // Watch for errors from various providers and consolidate them
  final appError = ref.watch(appErrorProvider);
  final settingsError = ref.watch(settingsProvider).errorMessage;
  final recordingsError = ref.watch(recordingsProvider).error;
  final recordingError = ref.watch(recordingProvider).errorMessage;
  final backgroundError = ref.watch(backgroundListeningProvider).errorMessage;
  
  // Clear individual provider errors when global error is cleared
  if (appError == null) {
    Future.microtask(() {
      if (settingsError != null) {
        ref.read(settingsProvider.notifier).clearError();
      }
      if (recordingsError != null) {
        ref.read(recordingsProvider.notifier).clearError();
      }
      if (recordingError != null) {
        ref.read(recordingProvider.notifier).clearError();
      }
      if (backgroundError != null) {
        ref.read(backgroundListeningProvider.notifier).clearError();
      }
    });
  }
});

/// Provider that ensures all state watchers are active
/// This should be watched by the main app to ensure synchronization is active
final stateWatchersProvider = Provider<bool>((ref) {
  // Watch all synchronization providers to ensure they're active
  ref.watch(stateSynchronizationProvider);
  ref.watch(stateRestorationProvider);
  ref.watch(errorManagementProvider);
  
  return true;
});