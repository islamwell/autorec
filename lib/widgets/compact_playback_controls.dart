import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/service_locator.dart';
import '../models/recording.dart';

/// Compact playback controls suitable for use in lists or cards
class CompactPlaybackControls extends ConsumerStatefulWidget {
  final Recording recording;
  final VoidCallback? onPlaybackComplete;
  final bool showProgress;
  final double iconSize;

  const CompactPlaybackControls({
    super.key,
    required this.recording,
    this.onPlaybackComplete,
    this.showProgress = true,
    this.iconSize = 24,
  });

  @override
  ConsumerState<CompactPlaybackControls> createState() => _CompactPlaybackControlsState();
}

class _CompactPlaybackControlsState extends ConsumerState<CompactPlaybackControls> {
  late AudioPlaybackService _playbackService;
  PlaybackState _currentState = PlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  String? _currentFilePath;

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
      if (mounted && _currentFilePath == widget.recording.filePath) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      // If we're playing a different file, stop it first
      if (_currentFilePath != widget.recording.filePath && _currentState == PlaybackState.playing) {
        await _playbackService.stop();
      }

      switch (_currentState) {
        case PlaybackState.stopped:
          _currentFilePath = widget.recording.filePath;
          await _playbackService.play(widget.recording.filePath);
          setState(() {
            _totalDuration = _playbackService.duration ?? widget.recording.duration;
          });
          break;
        case PlaybackState.playing:
          if (_currentFilePath == widget.recording.filePath) {
            await _playbackService.pause();
          } else {
            // Playing different file, start this one
            _currentFilePath = widget.recording.filePath;
            await _playbackService.play(widget.recording.filePath);
            setState(() {
              _totalDuration = _playbackService.duration ?? widget.recording.duration;
            });
          }
          break;
        case PlaybackState.paused:
          if (_currentFilePath == widget.recording.filePath) {
            await _playbackService.resume();
          } else {
            // Paused different file, start this one
            _currentFilePath = widget.recording.filePath;
            await _playbackService.play(widget.recording.filePath);
            setState(() {
              _totalDuration = _playbackService.duration ?? widget.recording.duration;
            });
          }
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getPlayPauseIcon() {
    final isCurrentFile = _currentFilePath == widget.recording.filePath;
    
    if (!isCurrentFile) {
      return Icons.play_arrow;
    }

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

  Color _getIconColor() {
    final theme = Theme.of(context);
    final isCurrentFile = _currentFilePath == widget.recording.filePath;
    
    if (!isCurrentFile) {
      return theme.colorScheme.primary;
    }

    switch (_currentState) {
      case PlaybackState.playing:
        return theme.colorScheme.secondary;
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return theme.colorScheme.primary;
      case PlaybackState.loading:
        return theme.colorScheme.tertiary;
      case PlaybackState.error:
        return theme.colorScheme.error;
    }
  }

  double _getProgress() {
    final isCurrentFile = _currentFilePath == widget.recording.filePath;
    if (!isCurrentFile || _totalDuration == null || _totalDuration!.inMilliseconds == 0) {
      return 0.0;
    }
    
    return (_currentPosition.inMilliseconds / _totalDuration!.inMilliseconds).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentFile = _currentFilePath == widget.recording.filePath;
    final isLoading = isCurrentFile && _currentState == PlaybackState.loading;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getIconColor().withOpacity(0.1),
          ),
          child: IconButton(
            onPressed: _currentState != PlaybackState.loading ? _togglePlayback : null,
            icon: isLoading
                ? SizedBox(
                    width: widget.iconSize * 0.7,
                    height: widget.iconSize * 0.7,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
                    ),
                  )
                : Icon(_getPlayPauseIcon()),
            iconSize: widget.iconSize,
            color: _getIconColor(),
            padding: EdgeInsets.all(widget.iconSize * 0.3),
            constraints: BoxConstraints(
              minWidth: widget.iconSize * 1.6,
              minHeight: widget.iconSize * 1.6,
            ),
          ),
        ),

        // Progress and time info
        if (widget.showProgress) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _getProgress(),
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCurrentFile 
                          ? _formatDuration(_currentPosition)
                          : '00:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.recording.duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    // Note: We don't dispose the service here as it's managed by the service locator
    super.dispose();
  }
}