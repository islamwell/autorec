import 'dart:io';
import '../../models/recording.dart';

/// Abstract interface for sharing and export functionality
abstract class SharingService {
  /// Exports a recording to the device downloads folder
  /// [recording] the recording to export
  /// [format] export format (mp3, wav, etc.)
  /// Returns the path to the exported file
  Future<String> exportToDownloads(Recording recording, {String format = 'mp3'});
  
  /// Exports multiple recordings to the device downloads folder
  /// [recordings] list of recordings to export
  /// [format] export format for individual files
  /// [createZip] whether to create a zip file containing all recordings
  /// Returns the path to the exported file(s) or zip file
  Future<String> exportMultipleToDownloads(
    List<Recording> recordings, {
    String format = 'mp3',
    bool createZip = false,
  });
  
  /// Shares a recording using the platform share sheet
  /// [recording] the recording to share
  /// [includeMetadata] whether to include metadata in the share text
  Future<void> shareRecording(Recording recording, {bool includeMetadata = true});
  
  /// Shares multiple recordings using the platform share sheet
  /// [recordings] list of recordings to share
  /// [createZip] whether to create a zip file for sharing
  /// [includeMetadata] whether to include metadata in the share text
  Future<void> shareMultipleRecordings(
    List<Recording> recordings, {
    bool createZip = true,
    bool includeMetadata = true,
  });
  
  /// Shares a recording file directly without using share sheet
  /// [recording] the recording to share
  /// [targetPath] destination path for the shared file
  Future<void> shareToPath(Recording recording, String targetPath);
  
  /// Gets the default downloads directory for the platform
  Future<Directory?> getDownloadsDirectory();
  
  /// Gets available sharing options for the current platform
  Future<List<SharingOption>> getAvailableSharingOptions();
  
  /// Checks if sharing is available on the current platform
  Future<bool> isSharingAvailable();
}

/// Represents a sharing option available on the platform
class SharingOption {
  final String id;
  final String name;
  final String description;
  final bool supportsMultipleFiles;
  final List<String> supportedFormats;
  
  const SharingOption({
    required this.id,
    required this.name,
    required this.description,
    required this.supportsMultipleFiles,
    required this.supportedFormats,
  });
}

/// Exception thrown when sharing operations fail
class SharingException implements Exception {
  final String message;
  final dynamic originalError;
  
  const SharingException(this.message, [this.originalError]);
  
  @override
  String toString() => 'SharingException: $message';
}