import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio/audio_recording_service.dart';
import 'audio/audio_playback_service.dart';
import 'keyword_detection/keyword_detection_service.dart';
import 'keyword_detection/keyword_training_service.dart';
import 'keyword_detection/keyword_training_service_impl.dart';
import 'keyword_detection/keyword_profile_service.dart';
import 'keyword_detection/keyword_profile_service_impl.dart';
import 'storage/file_storage_service.dart';
import 'storage/recording_manager_service.dart';
import 'storage/recording_manager_service_impl.dart';
import 'sharing/sharing_service.dart';
import 'sharing/sharing_service_impl.dart';
import 'permissions/permission_service.dart';
import 'background/background_listening_service.dart';
import 'timer/auto_stop_timer_service.dart';
import 'timer/auto_stop_timer_service_impl.dart';
import 'notifications/notification_service.dart';
import 'notifications/notification_service_impl.dart';
import 'state/state_persistence_service.dart';

/// Service locator using Riverpod providers for dependency injection
/// This file defines all the service providers that can be injected throughout the app

/// Provider for AudioRecordingService
/// This will be overridden with concrete implementation in main.dart
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  throw UnimplementedError('AudioRecordingService provider must be overridden');
});

/// Provider for AudioPlaybackService
/// This will be overridden with concrete implementation in main.dart
final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  throw UnimplementedError('AudioPlaybackService provider must be overridden');
});

/// Provider for KeywordDetectionService
/// This will be overridden with concrete implementation in main.dart
final keywordDetectionServiceProvider = Provider<KeywordDetectionService>((ref) {
  throw UnimplementedError('KeywordDetectionService provider must be overridden');
});

/// Provider for FileStorageService
/// This will be overridden with concrete implementation in main.dart
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  throw UnimplementedError('FileStorageService provider must be overridden');
});

/// Provider for PermissionService
/// This will be overridden with concrete implementation in main.dart
final permissionServiceProvider = Provider<PermissionService>((ref) {
  throw UnimplementedError('PermissionService provider must be overridden');
});

/// Provider for BackgroundListeningService
/// This will be overridden with concrete implementation in main.dart
final backgroundListeningServiceProvider = Provider<BackgroundListeningService>((ref) {
  throw UnimplementedError('BackgroundListeningService provider must be overridden');
});

/// Provider for AutoStopTimerService
/// This is created automatically and doesn't need to be overridden
final autoStopTimerServiceProvider = Provider<AutoStopTimerService>((ref) {
  return AutoStopTimerServiceImpl();
});

/// Provider for NotificationService
/// This is created automatically and doesn't need to be overridden
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});

/// Provider for RecordingManagerService
/// This depends on FileStorageService and is created automatically
final recordingManagerServiceProvider = Provider<RecordingManagerService>((ref) {
  final fileStorageService = ref.read(fileStorageServiceProvider);
  return RecordingManagerServiceImpl(fileStorageService);
});

/// Provider for KeywordTrainingService
/// This depends on AudioRecordingService and KeywordProfileService
final keywordTrainingServiceProvider = Provider<KeywordTrainingService>((ref) {
  final audioRecordingService = ref.read(audioRecordingServiceProvider);
  final profileService = ref.read(keywordProfileServiceProvider);
  return KeywordTrainingServiceImpl(audioRecordingService, profileService);
});

/// Provider for KeywordProfileService
/// This manages saved keyword profiles
final keywordProfileServiceProvider = Provider<KeywordProfileService>((ref) {
  return KeywordProfileServiceImpl();
});

/// Provider for SharingService
/// This depends on FileStorageService and is created automatically
final sharingServiceProvider = Provider<SharingService>((ref) {
  final fileStorageService = ref.read(fileStorageServiceProvider);
  return SharingServiceImpl(fileStorageService);
});

/// Provider for StatePersistenceService
/// This is created automatically and doesn't need to be overridden
final statePersistenceServiceProvider = Provider<StatePersistenceService>((ref) {
  return StatePersistenceServiceImpl();
});

/// Composite provider that ensures all required services are available
/// Useful for checking if the app is properly initialized
final servicesInitializedProvider = Provider<bool>((ref) {
  try {
    // Try to access all services to ensure they're properly configured
    ref.read(audioRecordingServiceProvider);
    ref.read(audioPlaybackServiceProvider);
    ref.read(keywordDetectionServiceProvider);
    ref.read(fileStorageServiceProvider);
    ref.read(permissionServiceProvider);
    ref.read(recordingManagerServiceProvider);
    ref.read(keywordTrainingServiceProvider);
    ref.read(keywordProfileServiceProvider);
    ref.read(backgroundListeningServiceProvider);
    ref.read(sharingServiceProvider);
    ref.read(autoStopTimerServiceProvider);
    ref.read(notificationServiceProvider);
    ref.read(statePersistenceServiceProvider);
    return true;
  } catch (e) {
    return false;
  }
});

/// Helper class for service registration
/// This will be used in main.dart to override providers with concrete implementations
class ServiceOverrides {
  static List<Override> create({
    required AudioRecordingService audioRecordingService,
    required AudioPlaybackService audioPlaybackService,
    required KeywordDetectionService keywordDetectionService,
    required FileStorageService fileStorageService,
    required PermissionService permissionService,
    required BackgroundListeningService backgroundListeningService,
  }) {
    return [
      audioRecordingServiceProvider.overrideWithValue(audioRecordingService),
      audioPlaybackServiceProvider.overrideWithValue(audioPlaybackService),
      keywordDetectionServiceProvider.overrideWithValue(keywordDetectionService),
      fileStorageServiceProvider.overrideWithValue(fileStorageService),
      permissionServiceProvider.overrideWithValue(permissionService),
      backgroundListeningServiceProvider.overrideWithValue(backgroundListeningService),
    ];
  }
}