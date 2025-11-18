import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_keyword_recorder/services/audio_features/mfcc_extractor.dart';

void main() {
  group('MfccExtractor', () {
    late MfccExtractor extractor;

    setUp(() {
      extractor = MfccExtractor(
        sampleRate: 16000,
        nMfcc: 13,
        nMels: 40,
        nFft: 512,
        hopLength: 160,
      );
    });

    group('Constructor and Initialization', () {
      test('should initialize with default parameters', () {
        final defaultExtractor = MfccExtractor();
        expect(defaultExtractor.sampleRate, equals(16000));
        expect(defaultExtractor.nMfcc, equals(13));
        expect(defaultExtractor.nMels, equals(40));
        expect(defaultExtractor.nFft, equals(512));
        expect(defaultExtractor.hopLength, equals(160));
      });

      test('should initialize with custom parameters', () {
        final customExtractor = MfccExtractor(
          sampleRate: 8000,
          nMfcc: 20,
          nMels: 26,
          nFft: 256,
          hopLength: 80,
        );
        expect(customExtractor.sampleRate, equals(8000));
        expect(customExtractor.nMfcc, equals(20));
        expect(customExtractor.nMels, equals(26));
      });
    });

    group('Feature Extraction', () {
      test('should return empty list for empty audio samples', () {
        final features = extractor.extractFeatures([]);
        expect(features, isEmpty);
      });

      test('should extract MFCC features from audio samples', () {
        // Create a simple sine wave (440 Hz for 0.5 seconds)
        final duration = 0.5;
        final frequency = 440.0;
        final sampleRate = 16000;
        final numSamples = (duration * sampleRate).toInt();

        final audioSamples = List.generate(numSamples, (i) {
          return sin(2 * pi * frequency * i / sampleRate);
        });

        final features = extractor.extractFeatures(audioSamples);

        // Should have features
        expect(features, isNotEmpty);

        // Each frame should have 13 MFCC coefficients
        for (final frame in features) {
          expect(frame.length, equals(13));
          // MFCCs should be finite numbers
          for (final coef in frame) {
            expect(coef.isFinite, isTrue);
            expect(coef.isNaN, isFalse);
          }
        }
      });

      test('should handle very short audio (less than one frame)', () {
        final shortAudio = List.generate(100, (i) => sin(2 * pi * i / 100));
        final features = extractor.extractFeatures(shortAudio);

        // Should still extract at least one frame
        expect(features, isNotEmpty);
        expect(features[0].length, equals(13));
      });

      test('should produce different features for different frequencies', () {
        final sampleRate = 16000;
        final numSamples = 8000; // 0.5 seconds

        // 440 Hz sine wave
        final audio440 = List.generate(numSamples, (i) {
          return sin(2 * pi * 440 * i / sampleRate);
        });

        // 880 Hz sine wave
        final audio880 = List.generate(numSamples, (i) {
          return sin(2 * pi * 880 * i / sampleRate);
        });

        final features440 = extractor.extractFeatures(audio440);
        final features880 = extractor.extractFeatures(audio880);

        // Features should be different
        expect(features440.length, greaterThan(0));
        expect(features880.length, greaterThan(0));

        // At least some coefficients should be significantly different
        bool foundDifference = false;
        for (int i = 0; i < min(features440.length, features880.length); i++) {
          for (int j = 0; j < 13; j++) {
            if ((features440[i][j] - features880[i][j]).abs() > 0.1) {
              foundDifference = true;
              break;
            }
          }
          if (foundDifference) break;
        }
        expect(foundDifference, isTrue, reason: 'Different frequencies should produce different MFCC features');
      });

      test('should handle normalized audio samples (-1.0 to 1.0)', () {
        final audioSamples = List.generate(1000, (i) {
          return (i % 2 == 0) ? 1.0 : -1.0; // Square wave
        });

        final features = extractor.extractFeatures(audioSamples);
        expect(features, isNotEmpty);

        for (final frame in features) {
          for (final coef in frame) {
            expect(coef.isFinite, isTrue);
          }
        }
      });
    });

    group('WAV File Parsing', () {
      test('should parse valid WAV file', () {
        // Create a minimal WAV file header
        final wavData = _createTestWavFile(
          sampleRate: 16000,
          numSamples: 1000,
          frequency: 440.0,
        );

        final features = extractor.extractFromWav(wavData);
        expect(features, isNotEmpty);
        expect(features[0].length, equals(13));
      });

      test('should return empty for WAV file with header only', () {
        final headerOnly = Uint8List(44);
        final features = extractor.extractFromWav(headerOnly);
        expect(features, isEmpty);
      });

      test('should return empty for corrupted WAV (too small)', () {
        final tooSmall = Uint8List(20);
        final features = extractor.extractFromWav(tooSmall);
        expect(features, isEmpty);
      });

      test('should handle WAV files with different amplitudes', () {
        final quietWav = _createTestWavFile(
          sampleRate: 16000,
          numSamples: 1000,
          frequency: 440.0,
          amplitude: 0.3,
        );

        final loudWav = _createTestWavFile(
          sampleRate: 16000,
          numSamples: 1000,
          frequency: 440.0,
          amplitude: 0.9,
        );

        final quietFeatures = extractor.extractFromWav(quietWav);
        final loudFeatures = extractor.extractFromWav(loudWav);

        expect(quietFeatures, isNotEmpty);
        expect(loudFeatures, isNotEmpty);

        // Both should produce valid features
        for (final frame in quietFeatures) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
        for (final frame in loudFeatures) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });
    });

    group('Similarity Computation', () {
      test('should return 1.0 for identical features', () {
        final audio = List.generate(1000, (i) => sin(2 * pi * 440 * i / 16000));
        final features1 = extractor.extractFeatures(audio);
        final features2 = extractor.extractFeatures(audio);

        final similarity = extractor.computeSimilarity(features1, features2);
        expect(similarity, greaterThan(0.9), reason: 'Identical features should have very high similarity');
      });

      test('should return 0.0 for empty features', () {
        final features = extractor.extractFeatures(List.generate(1000, (i) => sin(2 * pi * 440 * i / 16000)));
        final similarity = extractor.computeSimilarity(features, []);
        expect(similarity, equals(0.0));
      });

      test('should return similarity between 0 and 1', () {
        final audio1 = List.generate(1000, (i) => sin(2 * pi * 440 * i / 16000));
        final audio2 = List.generate(1000, (i) => sin(2 * pi * 880 * i / 16000));

        final features1 = extractor.extractFeatures(audio1);
        final features2 = extractor.extractFeatures(audio2);

        final similarity = extractor.computeSimilarity(features1, features2);
        expect(similarity, greaterThanOrEqualTo(0.0));
        expect(similarity, lessThanOrEqualTo(1.0));
      });

      test('should give higher similarity for similar frequencies', () {
        final audio440 = List.generate(1000, (i) => sin(2 * pi * 440 * i / 16000));
        final audio450 = List.generate(1000, (i) => sin(2 * pi * 450 * i / 16000)); // Close to 440
        final audio880 = List.generate(1000, (i) => sin(2 * pi * 880 * i / 16000)); // Far from 440

        final features440 = extractor.extractFeatures(audio440);
        final features450 = extractor.extractFeatures(audio450);
        final features880 = extractor.extractFeatures(audio880);

        final similaritySimilar = extractor.computeSimilarity(features440, features450);
        final similarityDifferent = extractor.computeSimilarity(features440, features880);

        expect(similaritySimilar, greaterThan(similarityDifferent),
            reason: 'Similar frequencies should have higher similarity than different frequencies');
      });

      test('should handle features of different lengths (DTW property)', () {
        final shortAudio = List.generate(500, (i) => sin(2 * pi * 440 * i / 16000));
        final longAudio = List.generate(1500, (i) => sin(2 * pi * 440 * i / 16000));

        final shortFeatures = extractor.extractFeatures(shortAudio);
        final longFeatures = extractor.extractFeatures(longAudio);

        final similarity = extractor.computeSimilarity(shortFeatures, longFeatures);

        // DTW should handle length differences
        expect(similarity, greaterThanOrEqualTo(0.0));
        expect(similarity, lessThanOrEqualTo(1.0));
        expect(similarity, greaterThan(0.5), reason: 'Same frequency at different lengths should still be similar');
      });
    });

    group('Edge Cases and Robustness', () {
      test('should handle silence (all zeros)', () {
        final silence = List.generate(1000, (_) => 0.0);
        final features = extractor.extractFeatures(silence);

        expect(features, isNotEmpty);
        for (final frame in features) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });

      test('should handle maximum amplitude', () {
        final maxAudio = List.generate(1000, (i) => (i % 2 == 0) ? 1.0 : -1.0);
        final features = extractor.extractFeatures(maxAudio);

        expect(features, isNotEmpty);
        for (final frame in features) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });

      test('should handle very low amplitude', () {
        final quietAudio = List.generate(1000, (i) => sin(2 * pi * 440 * i / 16000) * 0.001);
        final features = extractor.extractFeatures(quietAudio);

        expect(features, isNotEmpty);
        for (final frame in features) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });

      test('should handle noise', () {
        final random = Random(42); // Seeded for reproducibility
        final noise = List.generate(1000, (_) => random.nextDouble() * 2 - 1);
        final features = extractor.extractFeatures(noise);

        expect(features, isNotEmpty);
        for (final frame in features) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });

      test('should handle complex audio (multiple frequencies)', () {
        final complex = List.generate(1000, (i) {
          return sin(2 * pi * 440 * i / 16000) * 0.5 +
                 sin(2 * pi * 880 * i / 16000) * 0.3 +
                 sin(2 * pi * 1320 * i / 16000) * 0.2;
        });

        final features = extractor.extractFeatures(complex);
        expect(features, isNotEmpty);
        for (final frame in features) {
          expect(frame.every((c) => c.isFinite), isTrue);
        }
      });
    });

    group('FFT and Complex Numbers', () {
      test('FFT should handle power of 2 sizes', () {
        final fft = FFT();
        final input = List.generate(512, (i) => Complex(sin(2 * pi * i / 512), 0.0));

        expect(() => fft.transform(input), returnsNormally);
      });

      test('FFT should throw for non-power-of-2 sizes', () {
        final fft = FFT();
        final input = List.generate(100, (i) => Complex(sin(2 * pi * i / 100), 0.0));

        expect(() => fft.transform(input), throwsArgumentError);
      });

      test('Complex number magnitude should be correct', () {
        final c = Complex(3.0, 4.0);
        expect(c.magnitude, closeTo(5.0, 0.0001));
      });

      test('Complex number phase should be correct', () {
        final c = Complex(1.0, 1.0);
        expect(c.phase, closeTo(pi / 4, 0.0001));
      });
    });
  });
}

/// Helper function to create a test WAV file
Uint8List _createTestWavFile({
  required int sampleRate,
  required int numSamples,
  required double frequency,
  double amplitude = 0.8,
}) {
  // Create WAV header (44 bytes)
  final header = ByteData(44);

  // "RIFF" chunk
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F

  final fileSize = 36 + numSamples * 2;
  header.setUint32(4, fileSize, Endian.little);

  // "WAVE" format
  header.setUint8(8, 0x57);  // W
  header.setUint8(9, 0x41);  // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  // "fmt " subchunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // space

  header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
  header.setUint16(22, 1, Endian.little);  // NumChannels (1 = mono)
  header.setUint32(24, sampleRate, Endian.little); // SampleRate
  header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  header.setUint16(32, 2, Endian.little);  // BlockAlign
  header.setUint16(34, 16, Endian.little); // BitsPerSample

  // "data" subchunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a

  header.setUint32(40, numSamples * 2, Endian.little); // Subchunk2Size

  // Create audio data
  final audioData = ByteData(numSamples * 2);
  for (int i = 0; i < numSamples; i++) {
    final sample = sin(2 * pi * frequency * i / sampleRate) * amplitude;
    final intSample = (sample * 32767).toInt().clamp(-32768, 32767);
    audioData.setInt16(i * 2, intSample, Endian.little);
  }

  // Combine header and audio data
  final result = Uint8List(44 + numSamples * 2);
  result.setRange(0, 44, header.buffer.asUint8List());
  result.setRange(44, 44 + numSamples * 2, audioData.buffer.asUint8List());

  return result;
}
