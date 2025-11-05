import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recording.dart';
import '../services/storage/recording_manager_service.dart';
import '../services/service_locator.dart';

/// State class for managing recordings list
class RecordingsState {
  final List<Recording> recordings;
  final bool isLoading;
  final String? error;
  final RecordingFilter? currentFilter;
  final RecordingSortBy sortBy;
  final SortOrder sortOrder;

  const RecordingsState({
    this.recordings = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter,
    this.sortBy = RecordingSortBy.dateCreated,
    this.sortOrder = SortOrder.descending,
  });

  RecordingsState copyWith({
    List<Recording>? recordings,
    bool? isLoading,
    String? error,
    RecordingFilter? currentFilter,
    RecordingSortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return RecordingsState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilter: currentFilter ?? this.currentFilter,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasRecordings => recordings.isNotEmpty;
  bool get hasError => error != null;
}

/// Notifier for managing recordings list state
class RecordingsNotifier extends StateNotifier<RecordingsState> {
  final RecordingManagerService _recordingManager;

  RecordingsNotifier(this._recordingManager) : super(const RecordingsState()) {
    loadRecordings();
  }

  /// Loads all recordings with current filter and sort settings
  Future<void> loadRecordings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final recordings = await _recordingManager.getRecordings(
        filter: state.currentFilter,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );
      
      state = state.copyWith(
        recordings: recordings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recordings: ${e.toString()}',
      );
    }
  }

  /// Refreshes the recordings list
  Future<void> refreshRecordings() async {
    await loadRecordings();
  }

  /// Deletes a recording
  Future<void> deleteRecording(String id) async {
    try {
      await _recordingManager.deleteRecording(id);
      
      // Remove from current list
      final updatedRecordings = state.recordings
          .where((recording) => recording.id != id)
          .toList();
      
      state = state.copyWith(recordings: updatedRecordings);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete recording: ${e.toString()}',
      );
    }
  }

  /// Deletes multiple recordings
  Future<void> deleteMultipleRecordings(List<String> ids) async {
    try {
      final deletedCount = await _recordingManager.deleteMultipleRecordings(ids);
      
      // Remove deleted recordings from current list
      final updatedRecordings = state.recordings
          .where((recording) => !ids.contains(recording.id))
          .toList();
      
      state = state.copyWith(recordings: updatedRecordings);
      
      if (deletedCount < ids.length) {
        state = state.copyWith(
          error: 'Some recordings could not be deleted ($deletedCount/${ids.length} deleted)',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete recordings: ${e.toString()}',
      );
    }
  }

  /// Exports a recording
  Future<String?> exportRecording(String id) async {
    try {
      final exportPath = await _recordingManager.exportRecording(id);
      return exportPath;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to export recording: ${e.toString()}',
      );
      return null;
    }
  }

  /// Searches recordings
  Future<void> searchRecordings(String query) async {
    if (query.isEmpty) {
      await loadRecordings();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final recordings = await _recordingManager.searchRecordings(query);
      
      state = state.copyWith(
        recordings: recordings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search recordings: ${e.toString()}',
      );
    }
  }

  /// Applies filter to recordings
  Future<void> applyFilter(RecordingFilter? filter) async {
    state = state.copyWith(currentFilter: filter);
    await loadRecordings();
  }

  /// Changes sort settings
  Future<void> changeSorting(RecordingSortBy sortBy, SortOrder sortOrder) async {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    await loadRecordings();
  }

  /// Clears any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for the recordings notifier
final recordingsProvider = StateNotifierProvider<RecordingsNotifier, RecordingsState>((ref) {
  final recordingManager = ref.read(recordingManagerServiceProvider);
  return RecordingsNotifier(recordingManager);
});

/// Convenience providers for specific aspects of recordings state
final recordingsListProvider = Provider<List<Recording>>((ref) {
  return ref.watch(recordingsProvider).recordings;
});

final recordingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(recordingsProvider).isLoading;
});

final recordingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(recordingsProvider).error;
});

final hasRecordingsProvider = Provider<bool>((ref) {
  return ref.watch(recordingsProvider).hasRecordings;
});

/// Provider for getting a specific recording by ID
final recordingByIdProvider = Provider.family<Recording?, String>((ref, id) {
  final recordings = ref.watch(recordingsListProvider);
  try {
    return recordings.firstWhere((recording) => recording.id == id);
  } catch (e) {
    return null;
  }
});