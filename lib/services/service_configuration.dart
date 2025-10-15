import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_locator.dart';
import 'audio/audio_recording_service.dart';
import 'audio/audio_recording_service_impl.dart';
import 'audio/audio_playback_service.dart';
import 'audio/audio_playback_service_impl.dart';
import 'keyword_detection/keyword_detection_service.dart';
import 'keyword_detection/keyword_detection_service_impl.dart';
import 'storage/file_storage_service.dart';
import 'storage/file_storage_service_impl.dart';
import 'permissions/permission_service.dart';
import 'permissions/permission_service_impl.dart';
import 'background/background_listening_service.dart';
import 'background/background_listening_service_impl.dart';
import 'audio/audio_quality_analyzer.dart';
import '../models/models.dart';

/// Configuration class for setting up and managing service dependencies
class ServiceConfiguration {
  /// Initializes all services and returns provider overrides
  /// This method should be called in main.dart before running the app
  static Future<List<Override>> initializeServices() async {
    // Initialize real audio recording service
    final audioRecordingService = AudioRecordingServiceImpl();
    final audioPlaybackService = AudioPlaybackServiceImpl();
    final keywordDetectionService = KeywordDetectionServiceImpl();
    final fileStorageService = FileStorageServiceImpl();
    final permissionService = PermissionServiceImpl();
    final backgroundListeningService = BackgroundListeningServiceImpl();

    // Initialize services if needed
    // AudioRecordingServiceImpl initializes itself when first used
    // await fileStorageService.initialize();
    await permissionService.initializePlatformPermissions();

    return ServiceOverrides.create(
      audioRecordingService: audioRecordingService,
      audioPlaybackService: audioPlaybackService,
      keywordDetectionService: keywordDetectionService,
      fileStorageService: fileStorageService,
      permissionService: permissionService,
      backgroundListeningService: backgroundListeningService,
    );
  }

  /// Disposes all services and cleans up resources
  static Future<void> disposeServices() async {
    // TODO: Implement service disposal when concrete implementations are available
    // Service disposal will be handled by Riverpod automatically
  }
}

// Temporary mock implementations - these will be replaced with real implementations in later tasks

class _MockAudioRecordingService implements AudioRecordingService {
  @override
  Future<void> startRecording() => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Future<String> stopRecording() => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Stream<double> get audioLevelStream => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Future<void> configureForVoice() => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  bool get isRecording => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Duration get recordingDuration => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Future<void> dispose() => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  Stream<AudioQualityResult> get audioQualityStream => throw UnimplementedError('AudioRecordingService not implemented yet');

  @override
  AudioQualityResult? get currentAudioQuality => throw UnimplementedError('AudioRecordingService not implemented yet');
}



class _MockKeywordDetectionService implements KeywordDetectionService {
  @override
  Future<KeywordProfile> trainKeyword(String audioPath) => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> startListening() => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> stopListening() => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Stream<bool> get keywordDetectedStream => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Stream<double> get confidenceStream => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  bool get isListening => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  KeywordProfile? get currentProfile => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> loadProfile(KeywordProfile profile) => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> updateConfidenceThreshold(double threshold) => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> dispose() => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> configurePowerSettings({
    required bool lowPowerMode,
    required int batteryThreshold,
  }) => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  bool get isBackgroundListening => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> startBackgroundListening() => throw UnimplementedError('KeywordDetectionService not implemented yet');

  @override
  Future<void> stopBackgroundListening() => throw UnimplementedError('KeywordDetectionService not implemented yet');
}

class _MockFileStorageService implements FileStorageService {
  @override
  Future<String> saveRecording(String tempPath, Map<String, dynamic> metadata) => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<List<Recording>> getAllRecordings() => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<Recording?> getRecording(String id) => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<void> deleteRecording(String id) => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<String> exportToMp3(String recordingId) => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<int> getTotalStorageUsed() => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<int> getAvailableStorage() => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<void> cleanup({int? olderThanDays}) => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<String> createBackup() => throw UnimplementedError('FileStorageService not implemented yet');

  @override
  Future<void> restoreFromBackup(String backupPath) => throw UnimplementedError('FileStorageService not implemented yet');
}

class _MockPermissionService implements PermissionService {
  @override
  Future<PermissionStatus> checkPermission(AppPermission permission) => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Future<PermissionStatus> requestPermission(AppPermission permission) => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Future<Map<AppPermission, PermissionStatus>> requestMultiplePermissions(List<AppPermission> permissions) => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Future<bool> hasAllRequiredPermissions() => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Future<bool> openAppSettings() => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Future<bool> canRequestPermission(AppPermission permission) => throw UnimplementedError('PermissionService not implemented yet');

  @override
  String getPermissionRationale(AppPermission permission) => throw UnimplementedError('PermissionService not implemented yet');

  @override
  Stream<Map<AppPermission, PermissionStatus>> get permissionStatusStream => throw UnimplementedError('PermissionService not implemented yet');
}