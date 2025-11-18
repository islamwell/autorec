import 'dart:math';
import 'dart:typed_data';

/// MFCC (Mel-Frequency Cepstral Coefficients) Feature Extractor
///
/// Industry-standard audio feature extraction used in speech recognition
/// and keyword spotting applications. Converts raw audio into features
/// that represent the spectral characteristics of speech.
class MfccExtractor {
  final int sampleRate;
  final int nMfcc;
  final int nMels;
  final int nFft;
  final int hopLength;
  final double fMin;
  final double fMax;

  late final List<List<double>> _melFilterbank;
  late final FFT _fft;

  MfccExtractor({
    this.sampleRate = 16000,
    this.nMfcc = 13,
    this.nMels = 40,
    this.nFft = 512,
    this.hopLength = 160,
    this.fMin = 0.0,
    this.fMax = 8000.0,
  }) {
    _initializeMelFilterbank();
    _fft = FFT();
  }

  /// Extract MFCC features from audio samples
  ///
  /// [audioSamples] - Normalized audio samples (range -1.0 to 1.0)
  /// Returns a 2D list where each row is an MFCC feature vector for a time frame
  List<List<double>> extractFeatures(List<double> audioSamples) {
    if (audioSamples.isEmpty) {
      return [];
    }

    // Apply pre-emphasis to amplify high frequencies
    final preEmphasized = _preEmphasis(audioSamples);

    // Split audio into frames
    final frames = _frameSignal(preEmphasized);

    // Calculate MFCC for each frame
    final mfccFeatures = <List<double>>[];
    for (final frame in frames) {
      final mfcc = _computeMfcc(frame);
      mfccFeatures.add(mfcc);
    }

    return mfccFeatures;
  }

  /// Extract MFCC features from WAV file data
  ///
  /// [wavData] - Complete WAV file bytes including header
  /// Returns MFCC feature matrix
  List<List<double>> extractFromWav(Uint8List wavData) {
    final audioSamples = _parseWavFile(wavData);
    return extractFeatures(audioSamples);
  }

  /// Compute similarity between two MFCC feature sets using DTW
  ///
  /// Returns similarity score between 0.0 (no match) and 1.0 (perfect match)
  double computeSimilarity(List<List<double>> features1, List<List<double>> features2) {
    if (features1.isEmpty || features2.isEmpty) {
      return 0.0;
    }

    // Use Dynamic Time Warping (DTW) distance
    final dtwDistance = _computeDTW(features1, features2);

    // Normalize to 0-1 similarity score (lower DTW distance = higher similarity)
    // Using exponential decay to convert distance to similarity
    final similarity = exp(-dtwDistance / 10.0);

    return similarity.clamp(0.0, 1.0);
  }

  /// Compute MFCC for a single audio frame
  List<double> _computeMfcc(List<double> frame) {
    // Apply Hamming window
    final windowed = _applyHammingWindow(frame);

    // Compute FFT
    final fftResult = _computeFFT(windowed);

    // Compute power spectrum
    final powerSpectrum = _computePowerSpectrum(fftResult);

    // Apply Mel filterbank
    final melEnergies = _applyMelFilterbank(powerSpectrum);

    // Apply log
    final logMelEnergies = melEnergies.map((e) => log(e + 1e-10)).toList();

    // Apply DCT to get MFCC
    final mfcc = _applyDCT(logMelEnergies);

    return mfcc.sublist(0, nMfcc);
  }

  /// Apply pre-emphasis filter to boost high frequencies
  List<double> _preEmphasis(List<double> signal, [double coefficient = 0.97]) {
    final emphasized = List<double>.filled(signal.length, 0.0);
    emphasized[0] = signal[0];

    for (int i = 1; i < signal.length; i++) {
      emphasized[i] = signal[i] - coefficient * signal[i - 1];
    }

    return emphasized;
  }

  /// Split signal into overlapping frames
  List<List<double>> _frameSignal(List<double> signal) {
    final frames = <List<double>>[];
    int start = 0;

    while (start + nFft <= signal.length) {
      frames.add(signal.sublist(start, start + nFft));
      start += hopLength;
    }

    // Pad last frame if needed
    if (start < signal.length) {
      final lastFrame = List<double>.filled(nFft, 0.0);
      final remaining = signal.sublist(start);
      lastFrame.setRange(0, remaining.length, remaining);
      frames.add(lastFrame);
    }

    return frames;
  }

  /// Apply Hamming window to reduce spectral leakage
  List<double> _applyHammingWindow(List<double> frame) {
    final windowed = List<double>.filled(frame.length, 0.0);

    for (int i = 0; i < frame.length; i++) {
      final window = 0.54 - 0.46 * cos(2 * pi * i / (frame.length - 1));
      windowed[i] = frame[i] * window;
    }

    return windowed;
  }

  /// Compute FFT of the frame
  List<Complex> _computeFFT(List<double> frame) {
    // Pad to next power of 2 for efficient FFT
    final paddedLength = _nextPowerOf2(frame.length);
    final padded = List<double>.filled(paddedLength, 0.0);
    padded.setRange(0, frame.length, frame);

    // Convert to complex numbers
    final complexInput = padded.map((real) => Complex(real, 0.0)).toList();

    // Perform FFT
    return _fft.transform(complexInput);
  }

  /// Compute power spectrum from FFT result
  List<double> _computePowerSpectrum(List<Complex> fftResult) {
    final halfLength = (fftResult.length / 2).floor();
    final powerSpectrum = List<double>.filled(halfLength, 0.0);

    for (int i = 0; i < halfLength; i++) {
      final real = fftResult[i].real;
      final imag = fftResult[i].imaginary;
      powerSpectrum[i] = real * real + imag * imag;
    }

    return powerSpectrum;
  }

  /// Apply Mel filterbank to power spectrum
  List<double> _applyMelFilterbank(List<double> powerSpectrum) {
    final melEnergies = List<double>.filled(nMels, 0.0);

    for (int i = 0; i < nMels; i++) {
      double energy = 0.0;
      for (int j = 0; j < powerSpectrum.length; j++) {
        energy += _melFilterbank[i][j] * powerSpectrum[j];
      }
      melEnergies[i] = energy;
    }

    return melEnergies;
  }

  /// Apply Discrete Cosine Transform to get cepstral coefficients
  List<double> _applyDCT(List<double> melEnergies) {
    final dct = List<double>.filled(melEnergies.length, 0.0);

    for (int i = 0; i < dct.length; i++) {
      double sum = 0.0;
      for (int j = 0; j < melEnergies.length; j++) {
        sum += melEnergies[j] * cos(pi * i * (j + 0.5) / melEnergies.length);
      }
      dct[i] = sum;
    }

    return dct;
  }

  /// Initialize Mel filterbank
  void _initializeMelFilterbank() {
    // Convert Hz to Mel scale
    final melMin = _hzToMel(fMin);
    final melMax = _hzToMel(fMax);

    // Create equally spaced points in Mel scale
    final melPoints = <double>[];
    for (int i = 0; i <= nMels + 1; i++) {
      melPoints.add(melMin + (melMax - melMin) * i / (nMels + 1));
    }

    // Convert back to Hz
    final hzPoints = melPoints.map(_melToHz).toList();

    // Convert Hz to FFT bin numbers
    final binPoints = hzPoints.map((hz) {
      return ((nFft + 1) * hz / sampleRate).floor();
    }).toList();

    // Create filterbank
    _melFilterbank = List.generate(nMels, (_) => List.filled(nFft ~/ 2, 0.0));

    for (int i = 0; i < nMels; i++) {
      final leftBin = binPoints[i];
      final centerBin = binPoints[i + 1];
      final rightBin = binPoints[i + 2];

      // Triangular filter
      for (int j = leftBin; j < centerBin; j++) {
        if (j < _melFilterbank[i].length) {
          _melFilterbank[i][j] = (j - leftBin) / (centerBin - leftBin).toDouble();
        }
      }

      for (int j = centerBin; j < rightBin; j++) {
        if (j < _melFilterbank[i].length) {
          _melFilterbank[i][j] = (rightBin - j) / (rightBin - centerBin).toDouble();
        }
      }
    }
  }

  /// Convert frequency from Hz to Mel scale
  double _hzToMel(double hz) {
    return 2595.0 * log(1.0 + hz / 700.0) / ln10;
  }

  /// Convert frequency from Mel scale to Hz
  double _melToHz(double mel) {
    return 700.0 * (pow(10, mel / 2595.0) - 1.0);
  }

  /// Compute Dynamic Time Warping distance between two feature sequences
  double _computeDTW(List<List<double>> seq1, List<List<double>> seq2) {
    final n = seq1.length;
    final m = seq2.length;

    // Initialize DTW matrix
    final dtw = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));
    dtw[0][0] = 0.0;

    // Fill DTW matrix
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = _euclideanDistance(seq1[i - 1], seq2[j - 1]);
        dtw[i][j] = cost + [
          dtw[i - 1][j],     // Insertion
          dtw[i][j - 1],     // Deletion
          dtw[i - 1][j - 1], // Match
        ].reduce(min);
      }
    }

    // Normalize by path length
    return dtw[n][m] / (n + m);
  }

  /// Compute Euclidean distance between two feature vectors
  double _euclideanDistance(List<double> vec1, List<double> vec2) {
    double sum = 0.0;
    for (int i = 0; i < vec1.length && i < vec2.length; i++) {
      final diff = vec1[i] - vec2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Parse WAV file and extract audio samples
  /// Properly handles variable-length WAV headers by searching for the "data" chunk
  List<double> _parseWavFile(Uint8List wavData) {
    if (wavData.length < 44) {
      return [];
    }

    // Find the "data" chunk marker
    int dataStart = _findDataChunk(wavData);
    if (dataStart < 0) {
      // Fallback to standard header size if not found
      dataStart = 44;
    }

    if (dataStart >= wavData.length) {
      return [];
    }

    final audioData = wavData.sublist(dataStart);
    final samples = <double>[];

    // Parse 16-bit PCM samples (little-endian)
    for (int i = 0; i < audioData.length - 1; i += 2) {
      final byte1 = audioData[i];
      final byte2 = audioData[i + 1];

      // Combine bytes (little-endian: least significant byte first)
      final sample = byte1 | (byte2 << 8);

      // Convert from unsigned to signed 16-bit
      final signed = sample > 32767 ? sample - 65536 : sample;

      // Normalize to -1.0 to 1.0
      samples.add(signed / 32768.0);
    }

    return samples;
  }

  /// Find the start of the "data" chunk in a WAV file
  /// Returns the byte offset of the audio data, or -1 if not found
  int _findDataChunk(Uint8List wavData) {
    // Search for "data" marker (0x64617461 in little-endian)
    for (int i = 0; i < wavData.length - 8; i++) {
      if (wavData[i] == 0x64 &&      // 'd'
          wavData[i + 1] == 0x61 &&  // 'a'
          wavData[i + 2] == 0x74 &&  // 't'
          wavData[i + 3] == 0x61) {  // 'a'
        // Found "data" marker, skip marker (4 bytes) and size field (4 bytes)
        return i + 8;
      }
    }
    return -1; // Not found
  }

  /// Get next power of 2 for FFT efficiency
  int _nextPowerOf2(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }
}

/// Simple complex number class for FFT
class Complex {
  final double real;
  final double imaginary;

  const Complex(this.real, this.imaginary);

  double get magnitude => sqrt(real * real + imaginary * imaginary);
  double get phase => atan2(imaginary, real);

  @override
  String toString() => '$real + ${imaginary}i';
}

/// Simple FFT implementation
class FFT {
  List<Complex> transform(List<Complex> input) {
    final n = input.length;

    if (n <= 1) return input;
    if (n % 2 != 0) throw ArgumentError('FFT size must be power of 2');

    // Divide
    final even = <Complex>[];
    final odd = <Complex>[];

    for (int i = 0; i < n; i++) {
      if (i % 2 == 0) {
        even.add(input[i]);
      } else {
        odd.add(input[i]);
      }
    }

    // Conquer
    final evenFFT = transform(even);
    final oddFFT = transform(odd);

    // Combine
    final result = List<Complex>.filled(n, const Complex(0, 0));

    for (int k = 0; k < n ~/ 2; k++) {
      final angle = -2 * pi * k / n;
      final w = Complex(cos(angle), sin(angle));
      final t = Complex(
        w.real * oddFFT[k].real - w.imaginary * oddFFT[k].imaginary,
        w.real * oddFFT[k].imaginary + w.imaginary * oddFFT[k].real,
      );

      result[k] = Complex(
        evenFFT[k].real + t.real,
        evenFFT[k].imaginary + t.imaginary,
      );

      result[k + n ~/ 2] = Complex(
        evenFFT[k].real - t.real,
        evenFFT[k].imaginary - t.imaginary,
      );
    }

    return result;
  }
}
