import 'dart:async';
import 'auto_stop_timer_service.dart';

/// Implementation of AutoStopTimerService
class AutoStopTimerServiceImpl implements AutoStopTimerService {
  Timer? _timer;
  StreamController<Duration>? _remainingTimeController;
  StreamController<void>? _timerCompleteController;
  Duration _remainingTime = Duration.zero;
  Duration _originalDuration = Duration.zero;
  DateTime? _startTime;

  @override
  Stream<Duration> startTimer(Duration duration) {
    if (duration.inSeconds <= 0) {
      throw AutoStopTimerException('Timer duration must be greater than zero');
    }

    // Stop any existing timer
    stopTimer();

    // Initialize controllers
    _remainingTimeController = StreamController<Duration>.broadcast();
    _timerCompleteController ??= StreamController<void>.broadcast();

    _originalDuration = duration;
    _remainingTime = duration;
    _startTime = DateTime.now();

    // Start the timer with 1-second intervals
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });

    // Emit initial remaining time
    _remainingTimeController!.add(_remainingTime);

    return _remainingTimeController!.stream;
  }

  @override
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _remainingTimeController?.close();
    _remainingTimeController = null;
    _remainingTime = Duration.zero;
    _originalDuration = Duration.zero;
    _startTime = null;
  }

  @override
  Duration get remainingTime => _remainingTime;

  @override
  bool get isActive => _timer?.isActive ?? false;

  @override
  Stream<void> get onTimerComplete {
    _timerCompleteController ??= StreamController<void>.broadcast();
    return _timerCompleteController!.stream;
  }

  /// Updates the remaining time and handles timer completion
  void _updateRemainingTime() {
    if (_startTime == null) return;

    final elapsed = DateTime.now().difference(_startTime!);
    _remainingTime = _originalDuration - elapsed;

    if (_remainingTime.inSeconds <= 0) {
      // Timer completed
      _remainingTime = Duration.zero;
      _remainingTimeController?.add(_remainingTime);
      _timerCompleteController?.add(null);
      
      // Stop the timer
      _timer?.cancel();
      _timer = null;
      _remainingTimeController?.close();
      _remainingTimeController = null;
    } else {
      // Timer still running, emit remaining time
      _remainingTimeController?.add(_remainingTime);
    }
  }

  @override
  void dispose() {
    stopTimer();
    _timerCompleteController?.close();
    _timerCompleteController = null;
  }
}