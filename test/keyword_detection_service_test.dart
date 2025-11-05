import 'package:flutter_test/flutter_test.dart';
import 'package:voice_keyword_recorder/services/keyword_detection/keyword_detection_service_impl.dart';

void main() {
  group('KeywordDetectionServiceImpl', () {
    late KeywordDetectionServiceImpl service;

    setUp(() {
      service = KeywordDetectionServiceImpl();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should initialize with correct default state', () {
      expect(service.isListening, false);
      expect(service.currentProfile, null);
    });

    test('should update confidence threshold within valid range', () async {
      await service.updateConfidenceThreshold(0.8);
      // No exception should be thrown
    });

    test('should throw error for invalid confidence threshold', () async {
      expect(
        () => service.updateConfidenceThreshold(-0.1),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () => service.updateConfidenceThreshold(1.1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should provide empty streams when not initialized', () {
      expect(service.keywordDetectedStream, isA<Stream<bool>>());
      expect(service.confidenceStream, isA<Stream<double>>());
    });

    test('should handle dispose gracefully', () async {
      // Should not throw even when called multiple times
      await service.dispose();
      await service.dispose();
    });
  });
}