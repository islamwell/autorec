import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio/audio_playback_service.dart';
import '../services/service_locator.dart';
import '../models/recording.dart';

/// State class for managing current playback information
class AppPlaybackState {
  final Recording? currentRecording;
  final Duration position;
  final Duration? duration;
  final double speed;
  final PlaybackState state;
  final String? error;

  const AppPlaybackState({
    this.currentRecording,
    this.position = Duration.zero,
    this.duration,
    this.speed = 1.0,
    this.state = PlaybackState.stopped,
    this.error,
  });

  AppPlaybackState copyWith({
    Recording? currentRecording,
    Duration? position,
    Duration? duration,
    double? speed,
    PlaybackState? state,
    String? error,
  }) {
    return AppPlaybackState(
      currentRecording: currentRecording ?? this.currentRecording,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }

  bool get isPlaying => state == PlaybackState.playing;
  bool get isPaused => state == PlaybackState.paused;
  bool get isStopped => state == PlaybackState.stopped;
  bool get isLoading => state == PlaybackState.loading;
  bool get hasError => state == PlaybackState.error;
}

/// Notifier for managing playback state
class PlaybackNotifier extends StateNotifier<AppPlaybackState> {
  final AudioPlaybackService _playbackService;

  PlaybackNotifier(this._playbackService) : super(const AppPlaybackState()) {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to playback state changes
    _playbackService.stateStream.listen((serviceState) {
      final appState = _mapServiceStateToAppState(serviceState);
      state = state.copyWith(
        state: appState,
        error: serviceState == PlaybackState.error ? 'Playback error occurred' : null,
      );
    });

    // Listen to position changes
    _playbackService.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });
  }

  PlaybackState _mapServiceStateToAppState(PlaybackState serviceState) {
    // Since we're using the same enum, just return it directly
    return serviceState;
  }

  /// Plays a recording
  Future<void> playRecording(Recording recording) async {
    try {
      state = state.copyWith(
        currentRecording: recording,
        state: PlaybackState.loading,
        error: null,
      );

      await _playbackService.play(recording.filePath);
      
      state = state.copyWith(
        duration: _playbackService.duration,
        speed: _playbackService.speed,
      );
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Plays audio from a file path
  Future<void> playFile(String filePath) async {
    try {
      state = state.copyWith(
        currentRecording: null,
        state: PlaybackState.loading,
        error: null,
      );

      await _playbackService.play(filePath);
      
      state = state.copyWith(
        duration: _playbackService.duration,
        speed: _playbackService.speed,
      );
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Pauses playback
  Future<void> pause() async {
    try {
      await _playbackService.pause();
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Resumes playback
  Future<void> resume() async {
    try {
      await _playbackService.resume();
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Stops playback
  Future<void> stop() async {
    try {
      await _playbackService.stop();
      state = state.copyWith(
        position: Duration.zero,
        currentRecording: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Sets playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _playbackService.setSpeed(speed);
      state = state.copyWith(speed: speed);
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Seeks to a specific position
  Future<void> seekTo(Duration position) async {
    try {
      await _playbackService.seekTo(position);
      state = state.copyWith(position: position);
    } catch (e) {
      state = state.copyWith(
        state: PlaybackState.error,
        error: e.toString(),
      );
    }
  }

  /// Clears any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        error: null,
        state: PlaybackState.stopped,
      );
    }
  }

  @override
  void dispose() {
    // The service is managed by the service locator, so we don't dispose it here
    super.dispose();
  }
}

/// Provider for the playback notifier
final playbackProvider = StateNotifierProvider<PlaybackNotifier, AppPlaybackState>((ref) {
  final playbackService = ref.read(audioPlaybackServiceProvider);
  return PlaybackNotifier(playbackService);
});

/// Convenience providers for specific playback state aspects
final currentRecordingProvider = Provider<Recording?>((ref) {
  return ref.watch(playbackProvider).currentRecording;
});

final playbackPositionProvider = Provider<Duration>((ref) {
  return ref.watch(playbackProvider).position;
});

final playbackDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(playbackProvider).duration;
});

final playbackSpeedProvider = Provider<double>((ref) {
  return ref.watch(playbackProvider).speed;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackProvider).isPlaying;
});

final playbackErrorProvider = Provider<String?>((ref) {
  return ref.watch(playbackProvider).error;
});