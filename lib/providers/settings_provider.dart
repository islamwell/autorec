import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_settings.dart';
import 'background_listening_provider.dart';

/// State class for app settings
class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.settings == settings &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(settings, isLoading, errorMessage);
  }
}

/// Provider for managing app settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _settingsKey = 'app_settings';
  
  SettingsNotifier() : super(SettingsState(settings: AppSettings.defaultSettings())) {
    _loadSettings();
  }

  /// Load settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        final settings = AppSettings.fromJson(settingsMap);
        
        if (settings.isValid()) {
          state = state.copyWith(settings: settings, isLoading: false);
        } else {
          // Use default settings if loaded settings are invalid
          state = state.copyWith(
            settings: AppSettings.defaultSettings(),
            isLoading: false,
            errorMessage: 'Invalid settings detected, using defaults',
          );
        }
      } else {
        // No saved settings, use defaults
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: ${e.toString()}',
      );
    }
  }

  /// Save settings to persistent storage
  Future<void> _saveSettings(AppSettings settings) async {
    try {
      if (!settings.isValid()) {
        throw Exception('Invalid settings cannot be saved');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save settings: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Update auto-stop duration
  Future<void> updateAutoStopDuration(Duration duration) async {
    if (duration.inMinutes < 1 || duration.inMinutes > 60) {
      state = state.copyWith(
        errorMessage: 'Auto-stop duration must be between 1 and 60 minutes',
      );
      return;
    }

    try {
      final newSettings = state.settings.copyWith(autoStopDuration: duration);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Toggle keyword listening
  Future<void> toggleKeywordListening(bool enabled) async {
    try {
      final newSettings = state.settings.copyWith(keywordListeningEnabled: enabled);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Update playback speed
  Future<void> updatePlaybackSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) {
      state = state.copyWith(
        errorMessage: 'Playback speed must be between 0.5x and 2.0x',
      );
      return;
    }

    try {
      final newSettings = state.settings.copyWith(playbackSpeed: speed);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Update recording quality
  Future<void> updateRecordingQuality(AudioQuality quality) async {
    try {
      final newSettings = state.settings.copyWith(recordingQuality: quality);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Toggle background mode
  Future<void> toggleBackgroundMode(bool enabled) async {
    try {
      final newSettings = state.settings.copyWith(backgroundModeEnabled: enabled);
      await _saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings();
      await _saveSettings(defaultSettings);
      state = state.copyWith(settings: defaultSettings, errorMessage: null);
    } catch (e) {
      // Error message already set in _saveSettings
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for app settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Provider for current app settings
final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsProvider).settings;
});

/// Provider for auto-stop duration
final autoStopDurationProvider = Provider<Duration>((ref) {
  return ref.watch(settingsProvider).settings.autoStopDuration;
});

/// Provider for keyword listening enabled state
final keywordListeningEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).settings.keywordListeningEnabled;
});

/// Provider for playback speed
final playbackSpeedProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).settings.playbackSpeed;
});

/// Provider for recording quality
final recordingQualityProvider = Provider<AudioQuality>((ref) {
  return ref.watch(settingsProvider).settings.recordingQuality;
});

/// Provider for background mode enabled state
final backgroundModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).settings.backgroundModeEnabled;
});

/// Provider that watches for settings changes and updates background listening
final settingsWatcherProvider = Provider<void>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final backgroundNotifier = ref.read(backgroundListeningProvider.notifier);
  
  // Update background listening configuration when settings change
  Future.microtask(() async {
    try {
      await backgroundNotifier.configureSettings(settings);
    } catch (e) {
      // Handle error silently or log it
    }
  });
});