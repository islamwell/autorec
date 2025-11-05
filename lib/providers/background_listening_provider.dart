import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background/background_listening_service.dart';
import '../services/service_locator.dart';
import '../models/app_settings.dart';

/// State class for background listening
class BackgroundListeningState {
  final bool isListening;
  final int batteryLevel;
  final bool isPowerSaveMode;
  final String? errorMessage;
  final bool isInitialized;

  const BackgroundListeningState({
    this.isListening = false,
    this.batteryLevel = 100,
    this.isPowerSaveMode = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  BackgroundListeningState copyWith({
    bool? isListening,
    int? batteryLevel,
    bool? isPowerSaveMode,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return BackgroundListeningState(
      isListening: isListening ?? this.isListening,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isPowerSaveMode: isPowerSaveMode ?? this.isPowerSaveMode,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundListeningState &&
        other.isListening == isListening &&
        other.batteryLevel == batteryLevel &&
        other.isPowerSaveMode == isPowerSaveMode &&
        other.errorMessage == errorMessage &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode {
    return Object.hash(
      isListening,
      batteryLevel,
      isPowerSaveMode,
      errorMessage,
      isInitialized,
    );
  }
}

/// Provider for managing background listening state and operations
class BackgroundListeningNotifier extends StateNotifier<BackgroundListeningState> {
  final BackgroundListeningService _backgroundService;
  bool _hasInitialized = false;

  // SOLUTION 3: Lazy initialization - don't initialize until actually needed
  BackgroundListeningNotifier(this._backgroundService) : super(const BackgroundListeningState());

  /// Initialize the background listening provider (called lazily)
  Future<void> _initialize() async {
    if (_hasInitialized) return; // Already initialized

    try {
      // Listen to battery level changes
      _backgroundService.batteryLevelStream.listen((level) {
        state = state.copyWith(batteryLevel: level);
      });

      // Listen to power save mode changes
      _backgroundService.powerSaveModeStream.listen((isPowerSave) {
        state = state.copyWith(isPowerSaveMode: isPowerSave);
      });

      state = state.copyWith(isInitialized: true);
      _hasInitialized = true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to initialize background listening: ${e.toString()}',
      );
    }
  }

  /// Start background listening
  Future<void> startBackgroundListening() async {
    if (state.isListening) return;

    // Initialize on first use (lazy)
    await _initialize();

    try {
      state = state.copyWith(errorMessage: null);

      await _backgroundService.startBackgroundListening();

      state = state.copyWith(isListening: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isListening: false,
      );
      rethrow;
    }
  }

  /// Stop background listening
  Future<void> stopBackgroundListening() async {
    if (!state.isListening) return;

    try {
      await _backgroundService.stopBackgroundListening();
      
      state = state.copyWith(isListening: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Configure background listening settings
  Future<void> configureSettings(AppSettings settings) async {
    try {
      await _backgroundService.configureBackgroundSettings(settings);
      
      // Update listening state based on settings
      if (settings.backgroundModeEnabled && settings.keywordListeningEnabled) {
        if (!state.isListening) {
          await startBackgroundListening();
        }
      } else {
        if (state.isListening) {
          await stopBackgroundListening();
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to configure settings: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Setup platform-specific background mode
  Future<void> setupPlatformBackgroundMode() async {
    try {
      await _backgroundService.setupPlatformBackgroundMode();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to setup platform background mode: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _backgroundService.dispose();
    super.dispose();
  }
}

/// Provider for background listening state
final backgroundListeningProvider = StateNotifierProvider<BackgroundListeningNotifier, BackgroundListeningState>((ref) {
  final backgroundService = ref.read(backgroundListeningServiceProvider);
  return BackgroundListeningNotifier(backgroundService);
});

/// Provider for checking if background listening is supported
final backgroundListeningSupportedProvider = FutureProvider<bool>((ref) async {
  final backgroundService = ref.read(backgroundListeningServiceProvider);
  return await backgroundService.isBackgroundListeningSupported();
});

/// Provider for battery level monitoring
final batteryLevelProvider = Provider<int>((ref) {
  return ref.watch(backgroundListeningProvider).batteryLevel;
});

/// Provider for power save mode status
final powerSaveModeProvider = Provider<bool>((ref) {
  return ref.watch(backgroundListeningProvider).isPowerSaveMode;
});