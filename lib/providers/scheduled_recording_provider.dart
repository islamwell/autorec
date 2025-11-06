import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scheduled_recording.dart';
import '../services/scheduling/scheduled_recording_service.dart';
import '../services/service_locator.dart';

/// State for scheduled recordings
class ScheduledRecordingState {
  final List<ScheduledRecording> recordings;
  final bool isLoading;
  final String? errorMessage;
  final ScheduledRecording? nextRecording;

  const ScheduledRecordingState({
    this.recordings = const [],
    this.isLoading = false,
    this.errorMessage,
    this.nextRecording,
  });

  ScheduledRecordingState copyWith({
    List<ScheduledRecording>? recordings,
    bool? isLoading,
    String? errorMessage,
    ScheduledRecording? nextRecording,
  }) {
    return ScheduledRecordingState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      nextRecording: nextRecording,
    );
  }
}

/// Provider for managing scheduled recordings
class ScheduledRecordingNotifier extends StateNotifier<ScheduledRecordingState> {
  final ScheduledRecordingService _service;
  final Uuid _uuid = const Uuid();

  ScheduledRecordingNotifier(this._service) : super(const ScheduledRecordingState()) {
    loadRecordings();
  }

  /// Load all scheduled recordings
  Future<void> loadRecordings() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final recordings = await _service.getScheduledRecordings();
      final next = await _service.getNextScheduledRecording();

      state = state.copyWith(
        recordings: recordings,
        nextRecording: next,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading scheduled recordings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load scheduled recordings: ${e.toString()}',
      );
    }
  }

  /// Create a new scheduled recording
  Future<void> createRecording({
    required String name,
    required TimeOfDay time,
    required Duration duration,
  }) async {
    try {
      state = state.copyWith(errorMessage: null);

      final recording = ScheduledRecording(
        id: _uuid.v4(),
        name: name,
        time: time,
        duration: duration,
        createdAt: DateTime.now(),
      );

      await _service.createScheduledRecording(recording);
      await loadRecordings();

      if (kDebugMode) debugPrint('Scheduled recording created: $name');
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating scheduled recording: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create scheduled recording: ${e.toString()}',
      );
    }
  }

  /// Update an existing scheduled recording
  Future<void> updateRecording(ScheduledRecording recording) async {
    try {
      state = state.copyWith(errorMessage: null);

      await _service.updateScheduledRecording(recording);
      await loadRecordings();

      if (kDebugMode) debugPrint('Scheduled recording updated: ${recording.name}');
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating scheduled recording: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update scheduled recording: ${e.toString()}',
      );
    }
  }

  /// Delete a scheduled recording
  Future<void> deleteRecording(String id) async {
    try {
      state = state.copyWith(errorMessage: null);

      await _service.deleteScheduledRecording(id);
      await loadRecordings();

      if (kDebugMode) debugPrint('Scheduled recording deleted: $id');
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting scheduled recording: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete scheduled recording: ${e.toString()}',
      );
    }
  }

  /// Toggle a scheduled recording on/off
  Future<void> toggleRecording(String id, bool enabled) async {
    try {
      state = state.copyWith(errorMessage: null);

      await _service.toggleScheduledRecording(id, enabled);
      await loadRecordings();

      if (kDebugMode) debugPrint('Scheduled recording toggled: $id -> $enabled');
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling scheduled recording: $e');
      state = state.copyWith(
        errorMessage: 'Failed to toggle scheduled recording: ${e.toString()}',
      );
    }
  }

  /// Get the next trigger time for a recording
  DateTime getNextTriggerTime(ScheduledRecording recording) {
    return _service.getNextTriggerTime(recording);
  }
}

/// Provider for scheduled recordings
final scheduledRecordingProvider =
    StateNotifierProvider<ScheduledRecordingNotifier, ScheduledRecordingState>((ref) {
  final serviceAsync = ref.watch(scheduledRecordingServiceProvider);
  return serviceAsync.when(
    data: (service) => ScheduledRecordingNotifier(service),
    loading: () => ScheduledRecordingNotifier(_DummyScheduledRecordingService()),
    error: (_, __) => ScheduledRecordingNotifier(_DummyScheduledRecordingService()),
  );
});

/// Dummy service for loading/error states
class _DummyScheduledRecordingService implements ScheduledRecordingService {
  @override
  Future<List<ScheduledRecording>> getScheduledRecordings() async => [];

  @override
  Future<ScheduledRecording> createScheduledRecording(ScheduledRecording recording) async => recording;

  @override
  Future<ScheduledRecording> updateScheduledRecording(ScheduledRecording recording) async => recording;

  @override
  Future<void> deleteScheduledRecording(String id) async {}

  @override
  Future<ScheduledRecording> toggleScheduledRecording(String id, bool enabled) async =>
      ScheduledRecording(id: id, name: '', time: const TimeOfDay(hour: 0, minute: 0), duration: Duration.zero, createdAt: DateTime.now());

  @override
  Future<ScheduledRecording?> getNextScheduledRecording() async => null;

  @override
  bool shouldTriggerNow(ScheduledRecording recording) => false;

  @override
  DateTime getNextTriggerTime(ScheduledRecording recording) => DateTime.now();

  @override
  Future<void> dispose() async {}
}
