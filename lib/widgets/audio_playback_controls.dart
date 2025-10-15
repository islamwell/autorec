import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/service_locator.dart';

/// Widget that provides audio playback controls with progress tracking
class AudioPlaybackControls extends ConsumerStatefulWidget {
  final String? filePath;
  final VoidCallback? onPlaybackComplete;
  final EdgeInsets? padding;
  final bool showSpeedControl;
  final bool showSeekBar;

  const AudioPlaybackControls({
    super.key,
    this.filePath,
    this.onPlaybackComplete,
    this.padding,
    this.showSpeedControl = true,
    this.showSeekBar = true,
  });

  @override
  ConsumerState<AudioPlaybackControls> createState() => _AudioPlaybackControlsState();
}

class _AudioPlaybackControlsState extends ConsumerState<AudioPlaybackControls> {
  late AudioPlaybackService _playbackService;
  PlaybackState _currentState = PlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  double _currentSpeed = 1.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _playbackService = ref.read(audioPlaybackServiceProvider);
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to playback state changes
    _playbackService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
        
        // Call completion callback when playback finishes
        if (state == PlaybackState.stopped && widget.onPlaybackComplete != null) {
          widget.onPlaybackComplete!();
        }
      }
    });

    // Listen to position changes
    _playbackService.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _playPause() async {
    try {
      switch (_currentState) {
        case PlaybackState.stopped:
          if (widget.filePath != null) {
            await _playbackService.play(widget.filePath!);
            setState(() {
              _totalDuration = _playbackService.duration;
              _currentSpeed = _playbackService.speed;
            });
          }
          break;
        case PlaybackState.playing:
          await _playbackService.pause();
          break;
        case PlaybackState.paused:
          await _playbackService.resume();
          break;
        case PlaybackState.loading:
        case PlaybackState.error:
          // Do nothing for these states
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Playback error: ${e.toString()}');
    }
  }

  Future<void> _stop() async {
    try {
      await _playbackService.stop();
      setState(() {
        _currentPosition = Duration.zero;
      });
    } catch (e) {
      _showErrorSnackBar('Stop error: ${e.toString()}');
    }
  }

  Future<void> _setSpeed(double speed) async {
    try {
      await _playbackService.setSpeed(speed);
      setState(() {
        _currentSpeed = speed;
      });
    } catch (e) {
      _showErrorSnackBar('Speed change error: ${e.toString()}');
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _playbackService.seekTo(position);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showErrorSnackBar('Seek error: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getPlayPauseIcon() {
    switch (_currentState) {
      case PlaybackState.playing:
        return Icons.pause;
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return Icons.play_arrow;
      case PlaybackState.loading:
        return Icons.hourglass_empty;
      case PlaybackState.error:
        return Icons.error;
    }
  }

  Color _getPlayButtonColor() {
    switch (_currentState) {
      case PlaybackState.playing:
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return Theme.of(context).colorScheme.primary;
      case PlaybackState.loading:
        return Theme.of(context).colorScheme.secondary;
      case PlaybackState.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaybackAvailable = widget.filePath != null;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar and time display
          if (widget.showSeekBar && isPlaybackAvailable) ...[
            Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _totalDuration != null && _totalDuration!.inMilliseconds > 0
                            ? (_currentPosition.inMilliseconds / _totalDuration!.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: _totalDuration != null ? (value) {
                          setState(() {
                            _isDragging = true;
                            _currentPosition = Duration(
                              milliseconds: (_totalDuration!.inMilliseconds * value).round(),
                            );
                          });
                        } : null,
                        onChangeEnd: _totalDuration != null ? (value) {
                          _isDragging = false;
                          final newPosition = Duration(
                            milliseconds: (_totalDuration!.inMilliseconds * value).round(),
                          );
                          _seekTo(newPosition);
                        } : null,
                        activeColor: theme.colorScheme.primary,
                        inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration ?? Duration.zero),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Main control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop button
              IconButton(
                onPressed: isPlaybackAvailable && _currentState != PlaybackState.stopped
                    ? _stop
                    : null,
                icon: const Icon(Icons.stop),
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                  foregroundColor: theme.colorScheme.secondary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Play/Pause button (larger, primary)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPlayButtonColor(),
                      _getPlayButtonColor().withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getPlayButtonColor().withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: isPlaybackAvailable && _currentState != PlaybackState.loading
                      ? _playPause
                      : null,
                  icon: _currentState == PlaybackState.loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(_getPlayPauseIcon()),
                  iconSize: 48,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          // Speed control
          if (widget.showSpeedControl && isPlaybackAvailable) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Speed:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ...([0.5, 1.0, 1.5, 2.0].map((speed) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text('${speed}x'),
                    selected: _currentSpeed == speed,
                    onSelected: (_) => _setSpeed(speed),
                    selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                    checkmarkColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _currentSpeed == speed
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: _currentSpeed == speed
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ))),
              ],
            ),
          ],

          // Status indicator
          if (!isPlaybackAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No audio file selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Note: We don't dispose the service here as it's managed by the service locator
    super.dispose();
  }
}