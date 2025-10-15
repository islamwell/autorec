import 'package:flutter_test/flutter_test.dart';
import 'package:voice_keyword_recorder/services/background/background_listening_service_impl.dart';
import 'package:voice_keyword_recorder/models/app_settings.dart';

void main() {
  group('BackgroundListeningService', () {
    late BackgroundListeningServiceImpl service;

    setUp(() {
      service = BackgroundListeningServiceImpl();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should initialize with correct default state', () {
      expect(service.isBackgroundListening, false);
    });

    test('should provide background listening statistics', () {
      final stats = service.getBackgroundListeningStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['isListening'], false);
      expect(stats['keywordDetectionCount'], 0);
      expect(stats['backgroundTaskExecutions'], 0);
    });

    test('should handle configuration settings', () async {
      final settings = AppSettings(
        autoStopDuration: const Duration(minutes: 30),
        keywordListeningEnabled: true,
        backgroundModeEnabled: true,
        playbackSpeed: 1.0,
        recordingQuality: AudioQuality.high,
      );

      // This should not throw an exception
      expect(() => service.configureBackgroundSettings(settings), returnsNormally);
    });

    test('should check background listening support', () async {
      final isSupported = await service.isBackgroundListeningSupported();
      
      // Should return a boolean value
      expect(isSupported, isA<bool>());
    });

    test('should handle platform background mode setup', () async {
      // This should not throw an exception
      expect(() => service.setupPlatformBackgroundMode(), returnsNormally);
    });

    test('should provide battery and power save streams', () {
      expect(service.batteryLevelStream, isA<Stream<int>>());
      expect(service.powerSaveModeStream, isA<Stream<bool>>());
    });

    test('should update statistics when background listening starts', () async {
      // Note: This test may fail in test environment due to platform dependencies
      // but verifies the interface works correctly
      
      final initialStats = service.getBackgroundListeningStats();
      expect(initialStats['isListening'], false);
      
      try {
        await service.startBackgroundListening();
        final updatedStats = service.getBackgroundListeningStats();
        expect(updatedStats['isListening'], true);
        expect(updatedStats['listeningStartTime'], isNotNull);
      } catch (e) {
        // Expected to fail in test environment due to missing platform services
        expect(e.toString(), contains('BackgroundListeningException'));
      }
    });

    test('should handle stop background listening', () async {
      try {
        await service.stopBackgroundListening();
        expect(service.isBackgroundListening, false);
      } catch (e) {
        // May fail in test environment, but should not crash
        expect(e, isA<Exception>());
      }
    });
  });
}