import 'package:flutter/material.dart';
import '../services/audio/audio_quality_analyzer.dart';

/// Widget that displays real-time audio level and quality indicators
class AudioLevelIndicator extends StatelessWidget {
  final double audioLevel;
  final AudioQualityResult? qualityResult;
  final bool isRecording;

  const AudioLevelIndicator({
    super.key,
    required this.audioLevel,
    this.qualityResult,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio level bar
            _buildAudioLevelBar(context),
            const SizedBox(height: 16),
            
            // Quality indicators
            if (qualityResult != null) ...[
              _buildQualityIndicators(context),
              const SizedBox(height: 12),
            ],
            
            // Status text
            _buildStatusText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioLevelBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Audio Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  '${(audioLevel * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getAudioLevelColor(audioLevel),
                  ),
                ),
                const SizedBox(width: 8),
                // Real-time level indicator icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  child: Icon(
                    _getAudioLevelIcon(audioLevel),
                    color: _getAudioLevelColor(audioLevel),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Enhanced audio level bar with gradient background
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade200,
                        Colors.yellow.shade300,
                        Colors.orange.shade400,
                        Colors.red.shade500,
                      ],
                    ),
                  ),
                ),
                // Level indicator
                FractionallySizedBox(
                  widthFactor: audioLevel,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAudioLevelColor(audioLevel).withOpacity(0.8),
                          _getAudioLevelColor(audioLevel),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Animated pulse effect for active recording
                if (isRecording && audioLevel > 0.1)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Level range indicators
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quiet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
            Text(
              'Optimal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
            Text(
              'Loud',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityIndicators(BuildContext context) {
    final quality = qualityResult!;
    
    return Column(
      children: [
        // Overall quality
        Row(
          children: [
            Icon(
              _getQualityIcon(quality.quality),
              color: _getQualityColor(quality.quality),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quality.qualityDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Noise level
        Row(
          children: [
            Icon(
              _getNoiseIcon(quality.noiseLevel),
              color: _getNoiseColor(quality.noiseLevel),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quality.noiseDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        
        // Speech detection indicator with animation
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: quality.isSpeechDetected 
                ? Colors.green.shade50 
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: quality.isSpeechDetected 
                  ? Colors.green.shade300 
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  quality.isSpeechDetected 
                      ? Icons.record_voice_over 
                      : Icons.voice_over_off,
                  key: ValueKey(quality.isSpeechDetected),
                  color: quality.isSpeechDetected 
                      ? Colors.green.shade600 
                      : Colors.grey.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                quality.isSpeechDetected ? 'Speech detected' : 'No speech',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: quality.isSpeechDetected 
                      ? Colors.green.shade700 
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Signal-to-Noise Ratio indicator
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.graphic_eq,
              color: _getSNRColor(quality.signalToNoiseRatio),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'SNR: ${quality.signalToNoiseRatio.toStringAsFixed(1)} dB',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getSNRColor(quality.signalToNoiseRatio),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey.shade300,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (quality.signalToNoiseRatio / 30).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _getSNRColor(quality.signalToNoiseRatio),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Noise reduction recommendation
        if (quality.noiseReductionRecommended) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Consider noise reduction',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusText(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isRecording) {
      statusText = 'Recording in progress...';
      statusColor = Colors.red.shade600;
      statusIcon = Icons.fiber_manual_record;
    } else {
      statusText = 'Ready to record';
      statusColor = Colors.grey.shade600;
      statusIcon = Icons.mic;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getAudioLevelColor(double level) {
    if (level < 0.2) return Colors.green.shade400;
    if (level < 0.5) return Colors.yellow.shade600;
    if (level < 0.8) return Colors.orange.shade500;
    return Colors.red.shade600;
  }

  IconData _getAudioLevelIcon(double level) {
    if (level < 0.1) return Icons.volume_mute;
    if (level < 0.3) return Icons.volume_down;
    if (level < 0.7) return Icons.volume_up;
    return Icons.volume_up_outlined;
  }

  IconData _getQualityIcon(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.excellent:
        return Icons.signal_cellular_4_bar;
      case AudioQuality.good:
        return Icons.signal_cellular_alt;
      case AudioQuality.fair:
        return Icons.signal_cellular_alt_2_bar;
      case AudioQuality.poor:
        return Icons.signal_cellular_alt_1_bar;
    }
  }

  Color _getQualityColor(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.excellent:
        return Colors.green.shade600;
      case AudioQuality.good:
        return Colors.lightGreen.shade600;
      case AudioQuality.fair:
        return Colors.orange.shade600;
      case AudioQuality.poor:
        return Colors.red.shade600;
    }
  }

  IconData _getNoiseIcon(NoiseLevel noiseLevel) {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return Icons.volume_off;
      case NoiseLevel.moderate:
        return Icons.volume_down;
      case NoiseLevel.noisy:
        return Icons.volume_up;
      case NoiseLevel.veryNoisy:
        return Icons.volume_up_outlined;
    }
  }

  Color _getNoiseColor(NoiseLevel noiseLevel) {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return Colors.green.shade600;
      case NoiseLevel.moderate:
        return Colors.yellow.shade700;
      case NoiseLevel.noisy:
        return Colors.orange.shade600;
      case NoiseLevel.veryNoisy:
        return Colors.red.shade600;
    }
  }

  Color _getSNRColor(double snr) {
    if (snr >= 20) return Colors.green.shade600;
    if (snr >= 12) return Colors.lightGreen.shade600;
    if (snr >= 6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}