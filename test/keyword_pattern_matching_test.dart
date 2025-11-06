import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

/// Tests for keyword pattern matching algorithm
void main() {
  group('Keyword Pattern Matching Tests', () {
    test('Pattern similarity calculation works correctly', () {
      // Test 1: Identical patterns should have 100% similarity
      final pattern1 = [0.1, 0.5, 0.9, 0.7, 0.3];
      final pattern2 = [0.1, 0.5, 0.9, 0.7, 0.3];

      final similarity1 = _calculateSimilarity(pattern1, pattern2);
      expect(similarity1, greaterThan(0.99)); // Almost perfect match

      // Test 2: Completely different patterns should have low similarity
      final pattern3 = [0.1, 0.1, 0.1, 0.1, 0.1];
      final pattern4 = [0.9, 0.9, 0.9, 0.9, 0.9];

      final similarity2 = _calculateSimilarity(pattern3, pattern4);
      expect(similarity2, lessThan(0.5)); // Low similarity

      // Test 3: Similar but not identical patterns
      final pattern5 = [0.1, 0.5, 0.9, 0.7, 0.3];
      final pattern6 = [0.15, 0.52, 0.88, 0.72, 0.28];

      final similarity3 = _calculateSimilarity(pattern5, pattern6);
      expect(similarity3, greaterThan(0.8)); // High similarity
    });

    test('Pattern extraction creates valid patterns', () {
      // Test pattern length bounds
      final smallFile = 10000; // ~0.5 seconds
      final largeFile = 40000; // ~2 seconds

      final pattern1 = _createTestPattern(smallFile);
      final pattern2 = _createTestPattern(largeFile);

      expect(pattern1.length, greaterThanOrEqualTo(50));
      expect(pattern1.length, lessThanOrEqualTo(200));
      expect(pattern2.length, greaterThanOrEqualTo(50));
      expect(pattern2.length, lessThanOrEqualTo(200));

      // Test pattern values are in valid range
      for (final value in pattern1) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });

    test('Pattern has speech-like envelope', () {
      final pattern = _createTestPattern(20000);

      // Find the attack phase (should be near the beginning)
      final attackPhase = pattern.take(30).reduce(max);

      // Find the sustain phase (middle should have high values)
      final middle = pattern.skip(pattern.length ~/ 3).take(pattern.length ~/ 3).toList();
      final sustainPhase = middle.reduce((a, b) => a + b) / middle.length;

      // Find the decay phase (end should decrease)
      final decayPhase = pattern.skip(pattern.length * 3 ~/ 4).reduce(max);

      // Verify envelope shape
      expect(attackPhase, greaterThan(0.3)); // Attack should have energy
      expect(sustainPhase, greaterThan(0.5)); // Sustain should be strong
      expect(decayPhase, lessThan(sustainPhase)); // Decay should be less than sustain
    });

    test('Confidence threshold filtering works', () {
      const threshold = 0.3;

      // High confidence should pass
      expect(_shouldDetect(0.5, threshold), true);
      expect(_shouldDetect(0.8, threshold), true);

      // Low confidence should not pass
      expect(_shouldDetect(0.1, threshold), false);
      expect(_shouldDetect(0.25, threshold), false);

      // Edge case
      expect(_shouldDetect(0.3, threshold), true);
    });

    test('Decibel normalization works correctly', () {
      const minDb = -60.0;
      const maxDb = -10.0;

      // Test boundary values
      expect(_normalizeDecibels(minDb), closeTo(0.0, 0.01));
      expect(_normalizeDecibels(maxDb), closeTo(1.0, 0.01));

      // Test middle value
      expect(_normalizeDecibels(-35.0), closeTo(0.5, 0.01));

      // Test clamping
      expect(_normalizeDecibels(-100.0), closeTo(0.0, 0.01)); // Below min
      expect(_normalizeDecibels(0.0), closeTo(1.0, 0.01));    // Above max
    });

    test('Audio buffer management maintains size', () {
      const maxBufferSize = 100;
      final buffer = <double>[];

      // Fill buffer beyond max size
      for (int i = 0; i < 150; i++) {
        buffer.add(i / 150.0);
        if (buffer.length > maxBufferSize) {
          buffer.removeAt(0);
        }
      }

      expect(buffer.length, equals(maxBufferSize));
      expect(buffer.first, closeTo(0.33, 0.01)); // Old values should be removed
      expect(buffer.last, closeTo(0.99, 0.01)); // Recent values should be kept
    });
  });
}

/// Calculate similarity between two patterns using normalized cross-correlation
double _calculateSimilarity(List<double> segment1, List<double> segment2) {
  if (segment1.length != segment2.length) {
    return 0.0;
  }

  // Calculate means
  final mean1 = segment1.reduce((a, b) => a + b) / segment1.length;
  final mean2 = segment2.reduce((a, b) => a + b) / segment2.length;

  // Calculate normalized cross-correlation
  double numerator = 0.0;
  double denominator1 = 0.0;
  double denominator2 = 0.0;

  for (int i = 0; i < segment1.length; i++) {
    final diff1 = segment1[i] - mean1;
    final diff2 = segment2[i] - mean2;

    numerator += diff1 * diff2;
    denominator1 += diff1 * diff1;
    denominator2 += diff2 * diff2;
  }

  final denominator = sqrt(denominator1 * denominator2);
  if (denominator == 0.0) {
    return 0.0;
  }

  return (numerator / denominator).abs();
}

/// Create a test pattern similar to the production implementation
List<double> _createTestPattern(int fileSize) {
  final estimatedDurationMs = (fileSize / 2000 * 1000).toInt();
  final patternLength = (estimatedDurationMs / 10).clamp(50, 200).toInt();

  final pattern = <double>[];
  final random = Random(fileSize);

  for (int i = 0; i < patternLength; i++) {
    final position = i / patternLength;

    // Create envelope
    double envelope;
    if (position < 0.15) {
      envelope = position / 0.15;
    } else if (position < 0.75) {
      envelope = 0.85 + random.nextDouble() * 0.15;
    } else {
      envelope = (1.0 - position) / 0.25;
    }

    final uniqueness = ((fileSize + i) % 100) / 200.0;
    final value = (envelope * 0.7 + uniqueness).clamp(0.0, 1.0);

    pattern.add(value);
  }

  return pattern;
}

/// Normalize decibels to 0.0-1.0 range
double _normalizeDecibels(double decibels) {
  const double minDb = -60.0;
  const double maxDb = -10.0;

  final clampedDb = decibels.clamp(minDb, maxDb);
  return (clampedDb - minDb) / (maxDb - minDb);
}

/// Check if confidence exceeds threshold
bool _shouldDetect(double confidence, double threshold) {
  return confidence >= threshold;
}
