import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scheduled_recording.dart';
import '../audio/audio_recording_service.dart';
import '../storage/recording_manager_service.dart';
import 'scheduled_recording_service.dart';

/// Implementation of ScheduledRecordingService using SharedPreferences
class ScheduledRecordingServiceImpl implements ScheduledRecordingService {
  final SharedPreferences _prefs;
  final AudioRecordingService _audioService;
  final RecordingManagerService _recordingManager;

  static const String _storageKey = 'scheduled_recordings';

  final Map<String, Timer> _activeTimers = {};
  final StreamController<ScheduledRecording> _triggerController = StreamController.broadcast();

  /// Stream of scheduled recordings that have been triggered
  Stream<ScheduledRecording> get triggerStream => _triggerController.stream;

  ScheduledRecordingServiceImpl(
    this._prefs,
    this._audioService,
    this._recordingManager,
  ) {
    _initializeTimers();
  }

  /// Initialize timers for all enabled scheduled recordings
  Future<void> _initializeTimers() async {
    try {
      final recordings = await getScheduledRecordings();
      for (final recording in recordings) {
        if (recording.isEnabled) {
          _scheduleRecording(recording);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing timers: $e');
    }
  }

  @override
  Future<List<ScheduledRecording>> getScheduledRecordings() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => ScheduledRecording.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to load scheduled recordings: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<ScheduledRecording> createScheduledRecording(ScheduledRecording recording) async {
    try {
      final recordings = await getScheduledRecordings();
      recordings.add(recording);
      await _saveRecordings(recordings);

      // Schedule the recording if enabled
      if (recording.isEnabled) {
        _scheduleRecording(recording);
      }

      return recording;
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to create scheduled recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<ScheduledRecording> updateScheduledRecording(ScheduledRecording recording) async {
    try {
      final recordings = await getScheduledRecordings();
      final index = recordings.indexWhere((r) => r.id == recording.id);

      if (index == -1) {
        throw ScheduledRecordingException('Scheduled recording not found: ${recording.id}');
      }

      recordings[index] = recording;
      await _saveRecordings(recordings);

      // Cancel existing timer
      _cancelTimer(recording.id);

      // Reschedule if enabled
      if (recording.isEnabled) {
        _scheduleRecording(recording);
      }

      return recording;
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to update scheduled recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> deleteScheduledRecording(String id) async {
    try {
      final recordings = await getScheduledRecordings();
      recordings.removeWhere((r) => r.id == id);
      await _saveRecordings(recordings);

      // Cancel any active timer
      _cancelTimer(id);
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to delete scheduled recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<ScheduledRecording> toggleScheduledRecording(String id, bool enabled) async {
    try {
      final recordings = await getScheduledRecordings();
      final index = recordings.indexWhere((r) => r.id == id);

      if (index == -1) {
        throw ScheduledRecordingException('Scheduled recording not found: $id');
      }

      final updated = recordings[index].copyWith(isEnabled: enabled);
      recordings[index] = updated;
      await _saveRecordings(recordings);

      // Cancel existing timer
      _cancelTimer(id);

      // Schedule if enabled
      if (enabled) {
        _scheduleRecording(updated);
      }

      return updated;
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to toggle scheduled recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<ScheduledRecording?> getNextScheduledRecording() async {
    try {
      final recordings = await getScheduledRecordings();
      final enabled = recordings.where((r) => r.isEnabled).toList();

      if (enabled.isEmpty) return null;

      // Sort by next trigger time
      enabled.sort((a, b) {
        final aTime = getNextTriggerTime(a);
        final bTime = getNextTriggerTime(b);
        return aTime.compareTo(bTime);
      });

      return enabled.first;
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to get next scheduled recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  bool shouldTriggerNow(ScheduledRecording recording) {
    if (!recording.isEnabled) return false;

    final now = DateTime.now();
    return now.hour == recording.time.hour && now.minute == recording.time.minute;
  }

  @override
  DateTime getNextTriggerTime(ScheduledRecording recording) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      recording.time.hour,
      recording.time.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  /// Schedule a recording to trigger at the specified time
  void _scheduleRecording(ScheduledRecording recording) {
    final nextTrigger = getNextTriggerTime(recording);
    final delay = nextTrigger.difference(DateTime.now());

    if (kDebugMode) {
      debugPrint('Scheduling recording "${recording.name}" for ${recording.formattedTime}');
      debugPrint('Next trigger in: ${delay.inMinutes} minutes');
    }

    _activeTimers[recording.id] = Timer(delay, () async {
      await _executeScheduledRecording(recording);
    });
  }

  /// Execute a scheduled recording
  Future<void> _executeScheduledRecording(ScheduledRecording recording) async {
    try {
      if (kDebugMode) {
        debugPrint('=== EXECUTING SCHEDULED RECORDING ===');
        debugPrint('Name: ${recording.name}');
        debugPrint('Duration: ${recording.formattedDuration}');
      }

      // Emit trigger event
      _triggerController.add(recording);

      // Start recording
      await _audioService.startRecording();

      // Set timer to stop recording after duration
      Timer(recording.duration, () async {
        try {
          final audioPath = await _audioService.stopRecording();

          if (audioPath != null) {
            // Save the recording
            await _recordingManager.createRecording(
              audioPath,
              {
                'title': recording.name,
                'description': 'Scheduled recording at ${recording.formattedTime}',
                'isScheduled': true,
                'scheduledTime': DateTime.now().toIso8601String(),
              },
            );

            if (kDebugMode) {
              debugPrint('Scheduled recording saved successfully');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error saving scheduled recording: $e');
          }
        }
      });

      // Reschedule for tomorrow
      _scheduleRecording(recording);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error executing scheduled recording: $e');
      }
    }
  }

  /// Cancel a timer for a scheduled recording
  void _cancelTimer(String id) {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);
  }

  /// Save recordings to persistent storage
  Future<void> _saveRecordings(List<ScheduledRecording> recordings) async {
    try {
      final jsonList = recordings.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw ScheduledRecordingException(
        'Failed to save recordings: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Cancel all active timers
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    // Close stream controller
    await _triggerController.close();
  }
}
