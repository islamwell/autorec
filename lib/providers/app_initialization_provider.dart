import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state_provider.dart';
import 'settings_provider.dart';
import 'recordings_provider.dart';
import 'permission_provider.dart';
import 'background_listening_provider.dart';
import 'state_synchronization_provider.dart';
import '../services/service_locator.dart';

/// State for app initialization
class AppInitializationState {
  final bool isInitialized;
  final bool servicesReady;
  final bool permissionsChecked;
  final bool settingsLoaded;
  final bool recordingsLoaded;
  final String? initializationError;
  final double progress;

  const AppInitializationState({
    this.isInitialized = false,
    this.servicesReady = false,
    this.permissionsChecked = false,
    this.settingsLoaded = false,
    this.recordingsLoaded = false,
    this.initializationError,
    this.progress = 0.0,
  });

  AppInitializationState copyWith({
    bool? isInitialized,
    bool? servicesReady,
    bool? permissionsChecked,
    bool? settingsLoaded,
    bool? recordingsLoaded,
    String? initializationError,
    double? progress,
  }) {
    return AppInitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      servicesReady: servicesReady ?? this.servicesReady,
      permissionsChecked: permissionsChecked ?? this.permissionsChecked,
      settingsLoaded: settingsLoaded ?? this.settingsLoaded,
      recordingsLoaded: recordingsLoaded ?? this.recordingsLoaded,
      initializationError: initializationError,
      progress: progress ?? this.progress,
    );
  }

  bool get allComponentsReady => 
      servicesReady && permissionsChecked && settingsLoaded && recordingsLoaded;
}

/// Notifier for managing app initialization
class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  AppInitializationNotifier() : super(const AppInitializationState()) {
    _initializeApp();
  }

  /// Initialize the entire app in the correct order
  Future<void> _initializeApp() async {
    try {
      // Step 1: Check services (20% progress)
      await _checkServices();
      state = state.copyWith(servicesReady: true, progress: 0.2);

      // Step 2: Check permissions (40% progress)
      await _checkPermissions();
      state = state.copyWith(permissionsChecked: true, progress: 0.4);

      // Step 3: Load settings (60% progress)
      await _loadSettings();
      state = state.copyWith(settingsLoaded: true, progress: 0.6);

      // Step 4: Load recordings (80% progress)
      await _loadRecordings();
      state = state.copyWith(recordingsLoaded: true, progress: 0.8);

      // Step 5: Complete initialization (100% progress)
      await _finalizeInitialization();
      state = state.copyWith(isInitialized: true, progress: 1.0);

    } catch (e) {
      state = state.copyWith(
        initializationError: 'Failed to initialize app: ${e.toString()}',
        progress: 0.0,
      );
    }
  }

  /// Check if all services are properly configured
  Future<void> _checkServices() async {
    // This will throw if services are not properly configured
    // The servicesInitializedProvider will check all services
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate check
  }

  /// Check and initialize permissions
  Future<void> _checkPermissions() async {
    // Permissions will be checked by the permission provider
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate check
  }

  /// Load app settings
  Future<void> _loadSettings() async {
    // Settings will be loaded by the settings provider
    await Future.delayed(const Duration(milliseconds: 150)); // Simulate load
  }

  /// Load recordings list
  Future<void> _loadRecordings() async {
    // Recordings will be loaded by the recordings provider
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate load
  }

  /// Finalize initialization
  Future<void> _finalizeInitialization() async {
    // Any final setup steps
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate finalization
  }

  /// Retry initialization if it failed
  Future<void> retryInitialization() async {
    state = const AppInitializationState();
    await _initializeApp();
  }
}

/// Provider for app initialization state
final appInitializationProvider = StateNotifierProvider<AppInitializationNotifier, AppInitializationState>((ref) {
  return AppInitializationNotifier();
});

/// Provider that ensures all components are properly initialized
final appReadyProvider = Provider<bool>((ref) {
  // Watch all the key providers to ensure they're initialized
  final initState = ref.watch(appInitializationProvider);
  final servicesReady = ref.watch(servicesInitializedProvider);
  final appStateReady = ref.watch(appInitializedProvider);
  final stateWatchersActive = ref.watch(stateWatchersProvider);
  
  return initState.isInitialized && 
         servicesReady && 
         appStateReady && 
         stateWatchersActive;
});

/// Provider for initialization progress (0.0 to 1.0)
final initializationProgressProvider = Provider<double>((ref) {
  return ref.watch(appInitializationProvider).progress;
});

/// Provider for initialization error
final initializationErrorProvider = Provider<String?>((ref) {
  return ref.watch(appInitializationProvider).initializationError;
});

/// Provider that triggers initialization of all state providers
final stateProvidersInitializationProvider = Provider<void>((ref) {
  // Watch all providers to ensure they're initialized
  ref.watch(appStateProvider);
  ref.watch(settingsProvider);
  ref.watch(recordingsProvider);
  ref.watch(permissionStatusProvider);
  ref.watch(backgroundListeningProvider);
  
  // Ensure state synchronization is active
  ref.watch(stateWatchersProvider);
});