import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/audio/audio_recording_service.dart';
import '../../services/audio/audio_recording_service_impl.dart';
import '../../services/audio/audio_quality_analyzer.dart';
import '../../widgets/audio_level_indicator.dart';
import '../../widgets/permission_wrapper.dart';

/// Demo screen for testing real-time audio level monitoring and quality analysis
class AudioLevelDemoScreen extends StatefulWidget {
  const AudioLevelDemoScreen({super.key});

  @override
  State<AudioLevelDemoScreen> createState() => _AudioLevelDemoScreenState();
}

class _AudioLevelDemoScreenState extends State<AudioLevelDemoScreen> {
  late AudioRecordingService _audioService;
  StreamSubscription<double>? _audioLevelSubscription;
  StreamSubscription<AudioQualityResult>? _audioQualitySubscription;
  
  double _currentAudioLevel = 0.0;
  AudioQualityResult? _currentQualityResult;
  bool _isRecording = false;
  String? _lastRecordingPath;
  String? _errorMessage;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _audioService = AudioRecordingServiceImpl();
    _setupAudioStreams();
  }

  void _setupAudioStreams() {
    // Listen to audio level changes
    _audioLevelSubscription = _audioService.audioLevelStream.listen(
      (level) {
        if (mounted) {
          setState(() {
            _currentAudioLevel = level;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Audio level error: $error';
          });
        }
      },
    );

    // Listen to audio quality analysis results
    if (_audioService is AudioRecordingServiceImpl) {
      final serviceImpl = _audioService as AudioRecordingServiceImpl;
      _audioQualitySubscription = serviceImpl.audioQualityStream.listen(
        (qualityResult) {
          if (mounted) {
            setState(() {
              _currentQualityResult = qualityResult;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Audio quality error: $error';
            });
          }
        },
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _errorMessage = null;
        _lastRecordingPath = null;
      });

      await _audioService.startRecording();
      
      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = _audioService.recordingDuration;
          });
        }
      });

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: $e';
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _audioService.stopRecording();
      
      _durationTimer?.cancel();
      _durationTimer = null;

      setState(() {
        _isRecording = false;
        _lastRecordingPath = recordingPath;
        _currentAudioLevel = 0.0;
        _currentQualityResult = null;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: $e';
        _isRecording = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Level Monitor Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: PermissionWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recording controls
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Recording Controls',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Recording duration
                      if (_isRecording) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.red.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording: ${_formatDuration(_recordingDuration)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Record button
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording 
                              ? Colors.red.shade600 
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Audio level indicator
              AudioLevelIndicator(
                audioLevel: _currentAudioLevel,
                qualityResult: _currentQualityResult,
                isRecording: _isRecording,
              ),
              
              const SizedBox(height: 20),
              
              // Detailed metrics
              if (_currentQualityResult != null) ...[
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detailed Audio Metrics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildMetricRow(
                          'Signal-to-Noise Ratio',
                          '${_currentQualityResult!.signalToNoiseRatio.toStringAsFixed(1)} dB',
                          Icons.graphic_eq,
                        ),
                        
                        _buildMetricRow(
                          'Average Level',
                          '${(_currentQualityResult!.averageLevel * 100).toStringAsFixed(1)}%',
                          Icons.volume_up,
                        ),
                        
                        _buildMetricRow(
                          'Confidence Score',
                          '${(_currentQualityResult!.confidenceScore * 100).toStringAsFixed(1)}%',
                          Icons.psychology,
                        ),
                        
                        _buildMetricRow(
                          'Speech Detection',
                          _currentQualityResult!.isSpeechDetected ? 'Active' : 'None',
                          Icons.record_voice_over,
                          valueColor: _currentQualityResult!.isSpeechDetected 
                              ? Colors.green.shade600 
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Error display
              if (_errorMessage != null) ...[
                Card(
                  elevation: 4,
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _errorMessage = null),
                          icon: Icon(Icons.close, color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Last recording info
              if (_lastRecordingPath != null) ...[
                Card(
                  elevation: 4,
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Recording Saved',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Path: ${_lastRecordingPath!}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _audioLevelSubscription?.cancel();
    _audioQualitySubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}