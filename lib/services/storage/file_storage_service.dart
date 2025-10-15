import '../../models/recording.dart';

/// Abstract interface for file storage and management functionality
abstract class FileStorageService {
  /// Saves a recording from temporary path to permanent storage
  /// [tempPath] temporary file path of the recorded audio
  /// [metadata] additional metadata to associate with the recording
  /// Returns the permanent file path where the recording is saved
  /// Throws [FileStorageException] if saving fails
  Future<String> saveRecording(String tempPath, Map<String, dynamic> metadata);

  /// Retrieves all saved recordings with their metadata
  /// Returns list of [Recording] objects
  /// Throws [FileStorageException] if retrieval fails
  Future<List<Recording>> getAllRecordings();

  /// Gets a specific recording by its ID
  /// [id] unique identifier of the recording
  /// Returns [Recording] if found, null otherwise
  /// Throws [FileStorageException] if retrieval fails
  Future<Recording?> getRecording(String id);

  /// Deletes a recording and its associated files
  /// [id] unique identifier of the recording to delete
  /// Throws [FileStorageException] if deletion fails
  Future<void> deleteRecording(String id);

  /// Exports a recording to MP3 format
  /// [recordingId] ID of the recording to export
  /// Returns the path to the exported MP3 file
  /// Throws [FileStorageException] if export fails
  Future<String> exportToMp3(String recordingId);

  /// Gets the total storage space used by recordings
  /// Returns size in bytes
  Future<int> getTotalStorageUsed();

  /// Gets available storage space on device
  /// Returns available space in bytes
  Future<int> getAvailableStorage();

  /// Cleans up temporary files and old recordings
  /// [olderThanDays] delete recordings older than specified days (optional)
  Future<void> cleanup({int? olderThanDays});

  /// Creates a backup of all recordings metadata
  /// Returns the backup file path
  /// Throws [FileStorageException] if backup creation fails
  Future<String> createBackup();

  /// Restores recordings from a backup file
  /// [backupPath] path to the backup file
  /// Throws [FileStorageException] if restore fails
  Future<void> restoreFromBackup(String backupPath);
}

/// Exception thrown when file storage operations fail
class FileStorageException implements Exception {
  final String message;
  final dynamic originalError;

  const FileStorageException(this.message, [this.originalError]);

  @override
  String toString() => 'FileStorageException: $message';
}