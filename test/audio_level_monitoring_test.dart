import 'package:flutter_test/flutter_test.dart';
import 'package:voice_keyword_recorder/services/audio/audio_quality_analyzer.dart';

void main() {
  group('Audio Level Monitoring Tests', () {
    late AudioQualityAnalyzer analyzer;

    setUp(() {
      analyzer = AudioQualityAnalyzer();
    });

    test('should initialize with default values', () {
      expect(analyzer.currentQuality, isNull);
      expect(analyzer.isCalibrated, isFalse);
      expect(analyzer.backgroundNoiseLevel, equals(0.0));
    });

    test('should analyze audio levels and return quality results', () {
      // Simulate a series of audio levels
      final levels = [0.1, 0.2, 0.15, 0.3, 0.25, 0.4, 0.35, 0.5];
      
      AudioQualityResult? lastResult;
      for (final level in levels) {
        lastResult = analyzer.analyzeLevel(level);
      }

      expect(lastResult, isNotNull);
      expect(lastResult!.averageLevel, greaterThan(0.0));
      expect(lastResult.quality, isA<AudioQuality>());
      expect(lastResult.noiseLevel, isA<NoiseLevel>());
    });

    test('should detect speech patterns correctly', () {
      // Simulate speech-like audio levels with variation
      final speechLevels = [0.2, 0.4, 0.3, 0.5, 0.35, 0.6, 0.4, 0.7];
      
      AudioQualityResult? result;
      for (final level in speechLevels) {
        result = analyzer.analyzeLevel(level);
      }

      expect(result, isNotNull);
      expect(result!.isSpeechDetected, isTrue);
    });

    test('should not detect speech in low or constant levels', () {
      // Simulate constant low-level noise
      final noiseLevels = [0.05, 0.06, 0.05, 0.07, 0.06, 0.05, 0.06, 0.05];
      
      AudioQualityResult? result;
      for (final level in noiseLevels) {
        result = analyzer.analyzeLevel(level);
      }

      expect(result, isNotNull);
      expect(result!.isSpeechDetected, isFalse);
    });

    test('should calibrate background noise after sufficient samples', () {
      // Provide initial samples for calibration
      for (int i = 0; i < 25; i++) {
        analyzer.analyzeLevel(0.05 + (i % 3) * 0.01); // Small variation
      }

      expect(analyzer.isCalibrated, isTrue);
      expect(analyzer.backgroundNoiseLevel, greaterThan(0.0));
    });

    test('should determine appropriate noise levels', () {
      // Test quiet environment
      for (int i = 0; i < 10; i++) {
        analyzer.analyzeLevel(0.05);
      }
      var result = analyzer.analyzeLevel(0.06);
      expect(result.noiseLevel, equals(NoiseLevel.quiet));

      // Reset and test noisy environment
      analyzer.reset();
      for (int i = 0; i < 10; i++) {
        analyzer.analyzeLevel(0.3);
      }
      result = analyzer.analyzeLevel(0.4);
      expect(result.noiseLevel, isIn([NoiseLevel.moderate, NoiseLevel.noisy, NoiseLevel.veryNoisy]));
    });

    test('should calculate signal-to-noise ratio correctly', () {
      // Establish background noise
      for (int i = 0; i < 25; i++) {
        analyzer.analyzeLevel(0.05);
      }

      // Add signal above noise
      final result = analyzer.analyzeLevel(0.3);
      
      expect(result.signalToNoiseRatio, greaterThan(0.0));
    });

    test('should recommend noise reduction when appropriate', () {
      // Simulate very noisy environment
      for (int i = 0; i < 10; i++) {
        analyzer.analyzeLevel(0.6 + (i % 2) * 0.1);
      }
      
      final result = analyzer.analyzeLevel(0.7);
      expect(result.noiseReductionRecommended, isTrue);
    });

    test('should provide confidence scores', () {
      // Test with good quality audio
      for (int i = 0; i < 30; i++) {
        analyzer.analyzeLevel(0.1 + (i % 5) * 0.05);
      }
      
      final result = analyzer.analyzeLevel(0.3);
      expect(result.confidenceScore, greaterThan(0.0));
      expect(result.confidenceScore, lessThanOrEqualTo(1.0));
    });

    test('should reset state correctly', () {
      // Add some data
      for (int i = 0; i < 30; i++) {
        analyzer.analyzeLevel(0.2);
      }
      
      expect(analyzer.isCalibrated, isTrue);
      expect(analyzer.currentQuality, isNotNull);
      
      // Reset
      analyzer.reset();
      
      expect(analyzer.isCalibrated, isFalse);
      expect(analyzer.currentQuality, isNull);
      expect(analyzer.backgroundNoiseLevel, equals(0.0));
    });
  });

  group('AudioQualityResult Tests', () {
    test('should provide user-friendly descriptions', () {
      const result = AudioQualityResult(
        quality: AudioQuality.excellent,
        noiseLevel: NoiseLevel.quiet,
        signalToNoiseRatio: 25.0,
        averageLevel: 0.4,
        isSpeechDetected: true,
        noiseReductionRecommended: false,
        confidenceScore: 0.9,
      );

      expect(result.qualityDescription, contains('Excellent'));
      expect(result.noiseDescription, contains('Quiet'));
    });

    test('should handle all quality levels', () {
      for (final quality in AudioQuality.values) {
        final result = AudioQualityResult(
          quality: quality,
          noiseLevel: NoiseLevel.quiet,
          signalToNoiseRatio: 15.0,
          averageLevel: 0.3,
          isSpeechDetected: false,
          noiseReductionRecommended: false,
          confidenceScore: 0.7,
        );
        
        expect(result.qualityDescription, isNotEmpty);
      }
    });

    test('should handle all noise levels', () {
      for (final noiseLevel in NoiseLevel.values) {
        final result = AudioQualityResult(
          quality: AudioQuality.good,
          noiseLevel: noiseLevel,
          signalToNoiseRatio: 15.0,
          averageLevel: 0.3,
          isSpeechDetected: false,
          noiseReductionRecommended: false,
          confidenceScore: 0.7,
        );
        
        expect(result.noiseDescription, isNotEmpty);
      }
    });
  });
}