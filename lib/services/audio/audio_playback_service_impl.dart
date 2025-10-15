import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'audio_playback_service.dart';
import 'ios_audio_session_service.dart';

/// Implementation of AudioPlaybackService using flutter_sound
class AudioPlaybackServiceImpl implements AudioPlaybackService {
  FlutterSoundPlayer? _player;
  
  // State management
  PlaybackState _state = PlaybackState.stopped;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _speed = 1.0;
  String? _currentFilePath;
  
  // Stream controllers
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<PlaybackState> _stateController = StreamController<PlaybackState>.broadcast();
  
  // Timer for position updates
  Timer? _positionTimer;
  
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  
  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;
  
  @override
  Duration? get duration => _duration;
  
  @override
  Duration get position => _position;
  
  @override
  PlaybackState get state => _state;
  
  @override
  double get speed => _speed;

  /// Initializes the audio player
  Future<void> _initializePlayer() async {
    if (_player == null) {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      
      // Set up player callbacks
      _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    }
  }

  @override
  Future<void> play(String filePath) async {
    try {
      // Configure iOS audio session for playback
      await IOSAudioSessionService.configureForPlayback();
      await IOSAudioSessionService.activateSession();
      
      await _initializePlayer();
      
      // If we're playing a different file, stop current playback
      if (_currentFilePath != filePath && _state == PlaybackState.playing) {
        await stop();
      }
      
      _currentFilePath = filePath;
      
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw AudioPlaybackException('Audio file not found: $filePath');
      }
      
      _setState(PlaybackState.loading);
      
      // Start playback
      await _player!.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          _onPlaybackFinished();
        },
      );
      
      // Get duration using getProgress()
      try {
        final progress = await _player!.getProgress();
        if (progress != null && progress['duration'] != null) {
          _duration = progress['duration'] as Duration;
        } else {
          _duration = null;
        }
      } catch (_) {
        _duration = null;
      }
      
      _setState(PlaybackState.playing);
      _startPositionUpdates();
      
      // Apply current speed setting
      if (_speed != 1.0) {
        await _player!.setSpeed(_speed);
      }
      
    } catch (e) {
      _setState(PlaybackState.error);
      throw AudioPlaybackException('Failed to start playback: ${e.toString()}', e);
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_player == null || _state != PlaybackState.playing) {
        return;
      }
      
      await _player!.pausePlayer();
      _setState(PlaybackState.paused);
      _stopPositionUpdates();
      
    } catch (e) {
      _setState(PlaybackState.error);
      throw AudioPlaybackException('Failed to pause playback: ${e.toString()}', e);
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_player == null || _state != PlaybackState.paused) {
        return;
      }
      
      await _player!.resumePlayer();
      _setState(PlaybackState.playing);
      _startPositionUpdates();
      
    } catch (e) {
      _setState(PlaybackState.error);
      throw AudioPlaybackException('Failed to resume playback: ${e.toString()}', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_player == null) {
        return;
      }
      
      await _player!.stopPlayer();
      _setState(PlaybackState.stopped);
      _stopPositionUpdates();
      _position = Duration.zero;
      _positionController.add(_position);
      
    } catch (e) {
      _setState(PlaybackState.error);
      throw AudioPlaybackException('Failed to stop playback: ${e.toString()}', e);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) {
      throw ArgumentError('Speed must be between 0.5 and 2.0, got: $speed');
    }
    
    try {
      _speed = speed;
      
      // Apply speed if player is active
      if (_player != null && (_state == PlaybackState.playing || _state == PlaybackState.paused)) {
        await _player!.setSpeed(speed);
      }
      
    } catch (e) {
      throw AudioPlaybackException('Failed to set playback speed: ${e.toString()}', e);
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_duration != null && position > _duration!) {
      throw ArgumentError('Seek position cannot exceed audio duration');
    }
    
    if (position.isNegative) {
      throw ArgumentError('Seek position cannot be negative');
    }
    
    try {
      if (_player == null) {
        return;
      }
      
      await _player!.seekToPlayer(position);
      _position = position;
      _positionController.add(_position);
      
    } catch (e) {
      throw AudioPlaybackException('Failed to seek to position: ${e.toString()}', e);
    }
  }

  /// Sets the playback state and notifies listeners
  void _setState(PlaybackState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  /// Starts periodic position updates
  void _startPositionUpdates() {
    _stopPositionUpdates();
    
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_player != null && _state == PlaybackState.playing) {
        try {
          final currentPosition = await _player!.getProgress();
          if (currentPosition != null && currentPosition['position'] != null) {
            _position = currentPosition['position'] as Duration;
            _positionController.add(_position);
          }
        } catch (e) {
          // Ignore position update errors to avoid disrupting playback
        }
      }
    });
  }

  /// Stops position updates
  void _stopPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  /// Called when playback finishes naturally
  void _onPlaybackFinished() {
    _setState(PlaybackState.stopped);
    _stopPositionUpdates();
    _position = Duration.zero;
    _positionController.add(_position);
  }

  @override
  Future<void> dispose() async {
    _stopPositionUpdates();
    
    if (_player != null) {
      try {
        await _player!.stopPlayer();
        await _player!.closePlayer();
      } catch (e) {
        // Ignore disposal errors
      }
      _player = null;
    }
    
    await _positionController.close();
    await _stateController.close();
    
    _setState(PlaybackState.stopped);
  }
}