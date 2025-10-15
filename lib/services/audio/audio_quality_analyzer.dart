import 'dart:math';

/// Represents the quality of audio recording
enum AudioQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Represents noise level in the audio
enum NoiseLevel {
  quiet,
  moderate,
  noisy,
  veryNoisy,
}

/// Audio quality analysis result
class AudioQualityResult {
  final AudioQuality quality;
  final NoiseLevel noiseLevel;
  final double signalToNoiseRatio;
  final double averageLevel;
  final bool isSpeechDetected;
  final bool noiseReductionRecommended;
  final double confidenceScore;

  const AudioQualityResult({
    required this.quality,
    required this.noiseLevel,
    required this.signalToNoiseRatio,
    required this.averageLevel,
    required this.isSpeechDetected,
    required this.noiseReductionRecommended,
    required this.confidenceScore,
  });

  /// Get a user-friendly quality description
  String get qualityDescription {
    switch (quality) {
      case AudioQuality.excellent:
        return 'Excellent - Crystal clear audio';
      case AudioQuality.good:
        return 'Good - Clear voice recording';
      case AudioQuality.fair:
        return 'Fair - Acceptable quality';
      case AudioQuality.poor:
        return 'Poor - Consider moving to quieter location';
    }
  }

  /// Get noise level description with recommendations
  String get noiseDescription {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return 'Quiet environment - Optimal for recording';
      case NoiseLevel.moderate:
        return 'Some background noise detected';
      case NoiseLevel.noisy:
        return 'Noisy environment - Consider noise reduction';
      case NoiseLevel.veryNoisy:
        return 'Very noisy - Move to quieter location';
    }
  }

  @override
  String toString() {
    return 'AudioQualityResult(quality: $quality, noiseLevel: $noiseLevel, '
           'snr: ${signalToNoiseRatio.toStringAsFixed(1)}dB, '
           'avgLevel: ${averageLevel.toStringAsFixed(2)}, '
           'speechDetected: $isSpeechDetected, '
           'noiseReduction: $noiseReductionRecommended, '
           'confidence: ${confidenceScore.toStringAsFixed(2)})';
  }
}

/// Analyzes audio quality and noise levels in real-time
class AudioQualityAnalyzer {
  static const int _bufferSize = 50; // Keep last 50 samples (5 seconds at 100ms intervals)
  static const double _speechThreshold = 0.1; // Minimum level for speech detection
  static const double _noiseFloor = 0.05; // Background noise threshold
  
  final List<double> _levelBuffer = [];
  double _backgroundNoise = 0.0;
  int _sampleCount = 0;
  bool _isCalibrated = false;

  /// Analyze current audio level and return quality metrics
  AudioQualityResult analyzeLevel(double currentLevel) {
    _addSample(currentLevel);
    
    if (!_isCalibrated && _sampleCount >= 20) {
      _calibrateBackgroundNoise();
    }

    final averageLevel = _calculateAverageLevel();
    final noiseLevel = _determineNoiseLevel(currentLevel, averageLevel);
    final signalToNoiseRatio = _calculateSignalToNoiseRatio(averageLevel);
    final quality = _determineAudioQuality(signalToNoiseRatio, averageLevel);
    final isSpeechDetected = _detectSpeech(currentLevel, averageLevel);
    final noiseReductionRecommended = _shouldRecommendNoiseReduction(noiseLevel, signalToNoiseRatio);
    final confidenceScore = _calculateConfidenceScore(signalToNoiseRatio, averageLevel, noiseLevel);

    final result = AudioQualityResult(
      quality: quality,
      noiseLevel: noiseLevel,
      signalToNoiseRatio: signalToNoiseRatio,
      averageLevel: averageLevel,
      isSpeechDetected: isSpeechDetected,
      noiseReductionRecommended: noiseReductionRecommended,
      confidenceScore: confidenceScore,
    );

    _currentQuality = result;
    return result;
  }

  /// Add a new audio level sample to the buffer
  void _addSample(double level) {
    _levelBuffer.add(level);
    _sampleCount++;
    
    // Keep buffer size manageable
    if (_levelBuffer.length > _bufferSize) {
      _levelBuffer.removeAt(0);
    }
  }

  /// Calibrate background noise level from initial samples
  void _calibrateBackgroundNoise() {
    if (_levelBuffer.length < 10) return;
    
    // Use the lowest 30% of samples as background noise estimate
    final sortedLevels = List<double>.from(_levelBuffer)..sort();
    final noiseCount = (sortedLevels.length * 0.3).round();
    
    double noiseSum = 0.0;
    for (int i = 0; i < noiseCount; i++) {
      noiseSum += sortedLevels[i];
    }
    
    _backgroundNoise = noiseSum / noiseCount;
    _isCalibrated = true;
  }

  /// Calculate average level from recent samples
  double _calculateAverageLevel() {
    if (_levelBuffer.isEmpty) return 0.0;
    
    final sum = _levelBuffer.reduce((a, b) => a + b);
    return sum / _levelBuffer.length;
  }

  /// Determine noise level based on current and average levels
  NoiseLevel _determineNoiseLevel(double currentLevel, double averageLevel) {
    final noiseReference = max(_backgroundNoise, _noiseFloor);
    
    // Consider both average level and current level for more accurate assessment
    final combinedLevel = (averageLevel * 0.7) + (currentLevel * 0.3);
    
    // Enhanced noise level determination with better thresholds
    if (combinedLevel < noiseReference * 1.3) {
      return NoiseLevel.quiet;
    } else if (combinedLevel < noiseReference * 2.5) {
      return NoiseLevel.moderate;
    } else if (combinedLevel < noiseReference * 5.0) {
      return NoiseLevel.noisy;
    } else {
      return NoiseLevel.veryNoisy;
    }
  }

  /// Calculate signal-to-noise ratio in decibels
  double _calculateSignalToNoiseRatio(double averageLevel) {
    final noiseReference = max(_backgroundNoise, _noiseFloor);
    
    if (noiseReference == 0.0 || averageLevel <= noiseReference) {
      return 0.0; // No signal above noise
    }
    
    // Convert to dB: SNR = 20 * log10(signal/noise)
    return 20 * log(averageLevel / noiseReference) / ln10;
  }

  /// Determine overall audio quality based on SNR and level
  AudioQuality _determineAudioQuality(double snr, double averageLevel) {
    // Consider both SNR and absolute level
    if (snr >= 20 && averageLevel >= 0.3) {
      return AudioQuality.excellent;
    } else if (snr >= 12 && averageLevel >= 0.2) {
      return AudioQuality.good;
    } else if (snr >= 6 && averageLevel >= 0.1) {
      return AudioQuality.fair;
    } else {
      return AudioQuality.poor;
    }
  }

  /// Detect if speech is likely present in the audio
  bool _detectSpeech(double currentLevel, double averageLevel) {
    // Enhanced speech detection with multiple criteria
    if (currentLevel < _speechThreshold) return false;
    
    // Check for level variation (speech has more variation than steady noise)
    if (_levelBuffer.length < 5) return currentLevel > _speechThreshold;
    
    final recentLevels = _levelBuffer.skip(_levelBuffer.length - 5).toList();
    final variance = _calculateVariance(recentLevels);
    
    // Calculate dynamic range (difference between max and min recent levels)
    final maxLevel = recentLevels.reduce((a, b) => a > b ? a : b);
    final minLevel = recentLevels.reduce((a, b) => a < b ? a : b);
    final dynamicRange = maxLevel - minLevel;
    
    // Enhanced speech detection criteria:
    // 1. Current level above speech threshold
    // 2. Sufficient variance indicating modulation
    // 3. Good dynamic range indicating speech patterns
    // 4. Level significantly above background noise
    final hasVariance = variance > 0.008; // Slightly lower threshold for sensitivity
    final hasDynamicRange = dynamicRange > 0.15; // Speech has good dynamic range
    final aboveNoise = averageLevel > _backgroundNoise * 1.8; // Less strict noise requirement
    
    // Additional check for sustained speech patterns
    final sustainedSpeech = _checkSustainedSpeechPattern(recentLevels);
    
    return currentLevel > _speechThreshold && 
           (hasVariance || hasDynamicRange) && 
           aboveNoise &&
           sustainedSpeech;
  }

  /// Check for sustained speech patterns in recent audio levels
  bool _checkSustainedSpeechPattern(List<double> levels) {
    if (levels.length < 3) return true; // Not enough data, assume positive
    
    // Count how many levels are above speech threshold
    final speechLevels = levels.where((level) => level > _speechThreshold).length;
    
    // Speech should have at least 40% of recent samples above threshold
    return speechLevels >= (levels.length * 0.4);
  }

  /// Calculate variance of a list of values
  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((x) => pow(x - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Determine if noise reduction should be recommended
  bool _shouldRecommendNoiseReduction(NoiseLevel noiseLevel, double snr) {
    // Recommend noise reduction for noisy environments or poor SNR
    return noiseLevel == NoiseLevel.noisy || 
           noiseLevel == NoiseLevel.veryNoisy || 
           snr < 10.0;
  }

  /// Calculate confidence score for the quality assessment (0.0 to 1.0)
  double _calculateConfidenceScore(double snr, double averageLevel, NoiseLevel noiseLevel) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence with better SNR
    if (snr >= 20) {
      confidence += 0.3;
    } else if (snr >= 12) {
      confidence += 0.2;
    } else if (snr >= 6) {
      confidence += 0.1;
    }
    
    // Adjust based on signal level
    if (averageLevel >= 0.3) {
      confidence += 0.1;
    } else if (averageLevel < 0.1) {
      confidence -= 0.2;
    }
    
    // Adjust based on noise level
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        confidence += 0.1;
        break;
      case NoiseLevel.moderate:
        // No adjustment
        break;
      case NoiseLevel.noisy:
        confidence -= 0.1;
        break;
      case NoiseLevel.veryNoisy:
        confidence -= 0.2;
        break;
    }
    
    // Increase confidence if we have enough samples for calibration
    if (_isCalibrated && _sampleCount > 30) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Reset the analyzer state
  void reset() {
    _levelBuffer.clear();
    _backgroundNoise = 0.0;
    _sampleCount = 0;
    _isCalibrated = false;
    _currentQuality = null;
  }

  /// Get current background noise level
  double get backgroundNoiseLevel => _backgroundNoise;

  /// Check if analyzer is calibrated
  bool get isCalibrated => _isCalibrated;

  /// Get the most recent quality analysis result
  AudioQualityResult? _currentQuality;
  AudioQualityResult? get currentQuality => _currentQuality;
}