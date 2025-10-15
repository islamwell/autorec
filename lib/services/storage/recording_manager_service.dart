import '../../models/recording.dart';

/// Enum for sorting recordings
enum RecordingSortBy {
  dateCreated,
  duration,
  fileSize,
  keyword,
  alphabetical,
}

/// Enum for sort order
enum SortOrder {
  ascending,
  descending,
}

/// Filter criteria for recordings
class RecordingFilter {
  final String? keyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final Duration? minDuration;
  final Duration? maxDuration;
  final RecordingQuality? quality;
  final double? minFileSize; // in bytes
  final double? maxFileSize; // in bytes
  
  const RecordingFilter({
    this.keyword,
    this.startDate,
    this.endDate,
    this.minDuration,
    this.maxDuration,
    this.quality,
    this.minFileSize,
    this.maxFileSize,
  });
  
  /// Creates a filter for recordings from the last N days
  factory RecordingFilter.lastDays(int days) {
    return RecordingFilter(
      startDate: DateTime.now().subtract(Duration(days: days)),
    );
  }
  
  /// Creates a filter for recordings with a specific keyword
  factory RecordingFilter.byKeyword(String keyword) {
    return RecordingFilter(keyword: keyword);
  }
  
  /// Creates a filter for recordings within a duration range
  factory RecordingFilter.byDuration(Duration min, Duration max) {
    return RecordingFilter(
      minDuration: min,
      maxDuration: max,
    );
  }
}

/// Statistics about recordings
class RecordingStatistics {
  final int totalRecordings;
  final Duration totalDuration;
  final double totalFileSize; // in bytes
  final double averageFileSize; // in bytes
  final Duration averageDuration;
  final Map<RecordingQuality, int> qualityDistribution;
  final Map<String, int> keywordDistribution;
  final DateTime? oldestRecording;
  final DateTime? newestRecording;
  
  const RecordingStatistics({
    required this.totalRecordings,
    required this.totalDuration,
    required this.totalFileSize,
    required this.averageFileSize,
    required this.averageDuration,
    required this.qualityDistribution,
    required this.keywordDistribution,
    this.oldestRecording,
    this.newestRecording,
  });
}

/// Storage information
class StorageInfo {
  final int totalStorageUsed; // in bytes
  final int availableStorage; // in bytes
  final int totalStorage; // in bytes
  final double usagePercentage;
  final bool isLowStorage; // true if less than 10% available
  final bool isCriticalStorage; // true if less than 5% available
  
  const StorageInfo({
    required this.totalStorageUsed,
    required this.availableStorage,
    required this.totalStorage,
    required this.usagePercentage,
    required this.isLowStorage,
    required this.isCriticalStorage,
  });
}

/// Abstract interface for high-level recording management operations
abstract class RecordingManagerService {
  /// Gets all recordings with optional filtering and sorting
  /// [filter] optional filter criteria
  /// [sortBy] field to sort by
  /// [sortOrder] ascending or descending order
  /// [limit] maximum number of recordings to return
  /// [offset] number of recordings to skip (for pagination)
  Future<List<Recording>> getRecordings({
    RecordingFilter? filter,
    RecordingSortBy sortBy = RecordingSortBy.dateCreated,
    SortOrder sortOrder = SortOrder.descending,
    int? limit,
    int? offset,
  });
  
  /// Gets a specific recording by ID
  /// [id] unique identifier of the recording
  /// Returns the recording if found, null otherwise
  Future<Recording?> getRecording(String id);
  
  /// Creates a new recording from temporary file
  /// [tempPath] path to temporary recording file
  /// [metadata] recording metadata
  /// Returns the created recording
  Future<Recording> createRecording(String tempPath, Map<String, dynamic> metadata);
  
  /// Updates recording metadata
  /// [id] recording ID to update
  /// [updates] map of fields to update
  /// Returns the updated recording
  Future<Recording> updateRecording(String id, Map<String, dynamic> updates);
  
  /// Deletes a recording
  /// [id] recording ID to delete
  Future<void> deleteRecording(String id);
  
  /// Deletes multiple recordings
  /// [ids] list of recording IDs to delete
  /// Returns the number of successfully deleted recordings
  Future<int> deleteMultipleRecordings(List<String> ids);
  
  /// Gets recording statistics
  /// [filter] optional filter to apply before calculating statistics
  Future<RecordingStatistics> getStatistics({RecordingFilter? filter});
  
  /// Gets storage information
  Future<StorageInfo> getStorageInfo();
  
  /// Searches recordings by text content (keyword, filename, etc.)
  /// [query] search query
  /// [limit] maximum number of results
  Future<List<Recording>> searchRecordings(String query, {int? limit});
  
  /// Gets recordings grouped by keyword
  /// Returns a map where keys are keywords and values are lists of recordings
  Future<Map<String, List<Recording>>> getRecordingsByKeyword();
  
  /// Gets recordings grouped by date (day)
  /// Returns a map where keys are dates and values are lists of recordings
  Future<Map<DateTime, List<Recording>>> getRecordingsByDate();
  
  /// Exports recording to external storage
  /// [id] recording ID to export
  /// [format] export format (mp3, wav, etc.)
  /// Returns the path to the exported file
  Future<String> exportRecording(String id, {String format = 'mp3'});
  
  /// Exports multiple recordings as a zip file
  /// [ids] list of recording IDs to export
  /// [format] export format for individual files
  /// Returns the path to the zip file
  Future<String> exportMultipleRecordings(List<String> ids, {String format = 'mp3'});
  
  /// Cleans up old recordings based on criteria
  /// [olderThanDays] delete recordings older than specified days
  /// [keepMinimum] minimum number of recordings to keep
  /// Returns the number of deleted recordings
  Future<int> cleanupOldRecordings({int? olderThanDays, int? keepMinimum});
  
  /// Creates a backup of all recording metadata
  /// Returns the path to the backup file
  Future<String> createBackup();
  
  /// Restores recordings from a backup file
  /// [backupPath] path to the backup file
  Future<void> restoreFromBackup(String backupPath);
  
  /// Validates recording file integrity
  /// [id] recording ID to validate
  /// Returns true if file exists and is valid
  Future<bool> validateRecording(String id);
  
  /// Validates all recordings and returns list of invalid ones
  /// Returns list of recording IDs that are invalid or missing files
  Future<List<String>> validateAllRecordings();
  
  /// Gets duplicate recordings based on content similarity
  /// Returns groups of potentially duplicate recordings
  Future<List<List<Recording>>> findDuplicateRecordings();
}