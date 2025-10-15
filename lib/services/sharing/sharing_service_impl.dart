import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';

import '../../models/recording.dart';
import '../storage/file_storage_service.dart';
import 'sharing_service.dart';

/// Implementation of SharingService for managing recording sharing and export
class SharingServiceImpl implements SharingService {
  final FileStorageService _fileStorageService;
  
  SharingServiceImpl(this._fileStorageService);
  
  @override
  Future<String> exportToDownloads(Recording recording, {String format = 'mp3'}) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw SharingException('Downloads directory not available on this platform');
      }
      
      // Create VoiceRecordings subdirectory
      final exportDir = Directory(path.join(downloadsDir.path, 'VoiceRecordings'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      // Generate export filename with timestamp and keyword
      final timestamp = recording.createdAt.millisecondsSinceEpoch;
      final keyword = recording.keyword ?? 'recording';
      final sanitizedKeyword = _sanitizeFilename(keyword);
      final exportFileName = '${sanitizedKeyword}_$timestamp.$format';
      final exportPath = path.join(exportDir.path, exportFileName);
      
      // Check if source file exists
      final sourceFile = File(recording.filePath);
      if (!await sourceFile.exists()) {
        throw SharingException('Recording file not found: ${recording.filePath}');
      }
      
      // Handle different export formats
      if (format.toLowerCase() == 'mp3') {
        // Check if source is already MP3
        final sourceExtension = path.extension(recording.filePath).toLowerCase();
        if (sourceExtension == '.mp3') {
          // Just copy the MP3 file
          await sourceFile.copy(exportPath);
        } else {
          // Use existing export functionality from FileStorageService
          final tempExportPath = await _fileStorageService.exportToMp3(recording.id);
          final tempFile = File(tempExportPath);
          await tempFile.copy(exportPath);
          // Clean up temporary export file
          try {
            await tempFile.delete();
          } catch (e) {
            // Log but don't fail if cleanup fails
            print('Warning: Failed to delete temporary export file: $e');
          }
        }
      } else if (format.toLowerCase() == 'wav') {
        // For WAV format, copy original if it's WAV, otherwise we'd need conversion
        final sourceExtension = path.extension(recording.filePath).toLowerCase();
        if (sourceExtension == '.wav') {
          await sourceFile.copy(exportPath);
        } else {
          throw SharingException('WAV export from MP3 not supported yet');
        }
      } else {
        throw SharingException('Export format not supported: $format');
      }
      
      return exportPath;
    } catch (e) {
      if (e is SharingException) rethrow;
      throw SharingException('Failed to export recording to downloads', e);
    }
  }
  
  @override
  Future<String> exportMultipleToDownloads(
    List<Recording> recordings, {
    String format = 'mp3',
    bool createZip = false,
  }) async {
    try {
      if (recordings.isEmpty) {
        throw SharingException('No recordings to export');
      }
      
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw SharingException('Downloads directory not available on this platform');
      }
      
      // Create VoiceRecordings subdirectory
      final exportDir = Directory(path.join(downloadsDir.path, 'VoiceRecordings'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      if (createZip) {
        // Create a zip file containing all recordings
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final zipFileName = 'voice_recordings_$timestamp.zip';
        final zipPath = path.join(exportDir.path, zipFileName);
        
        final archive = Archive();
        
        for (int i = 0; i < recordings.length; i++) {
          final recording = recordings[i];
          
          // Export individual recording to temporary location
          final tempExportPath = await exportToDownloads(recording, format: format);
          final tempFile = File(tempExportPath);
          
          if (await tempFile.exists()) {
            final fileBytes = await tempFile.readAsBytes();
            final fileName = path.basename(tempExportPath);
            
            // Add file to archive
            final archiveFile = ArchiveFile(fileName, fileBytes.length, fileBytes);
            archive.addFile(archiveFile);
            
            // Clean up temporary file
            try {
              await tempFile.delete();
            } catch (e) {
              print('Warning: Failed to delete temporary file: $e');
            }
          }
        }
        
        // Write zip file
        final zipEncoder = ZipEncoder();
        final zipBytes = zipEncoder.encode(archive);
        if (zipBytes != null) {
          await File(zipPath).writeAsBytes(zipBytes);
        }
        
        return zipPath;
      } else {
        // Export individual files and return the directory path
        final exportedPaths = <String>[];
        
        for (final recording in recordings) {
          try {
            final exportPath = await exportToDownloads(recording, format: format);
            exportedPaths.add(exportPath);
          } catch (e) {
            print('Warning: Failed to export recording ${recording.id}: $e');
          }
        }
        
        if (exportedPaths.isEmpty) {
          throw SharingException('Failed to export any recordings');
        }
        
        return exportDir.path; // Return directory containing all exported files
      }
    } catch (e) {
      if (e is SharingException) rethrow;
      throw SharingException('Failed to export multiple recordings', e);
    }
  }
  
  @override
  Future<void> shareRecording(Recording recording, {bool includeMetadata = true}) async {
    try {
      final sourceFile = File(recording.filePath);
      if (!await sourceFile.exists()) {
        throw SharingException('Recording file not found: ${recording.filePath}');
      }
      
      // Prepare share text
      String shareText = 'Voice Recording';
      if (includeMetadata) {
        shareText = _buildShareText(recording);
      }
      
      // Share the file
      await Share.shareXFiles(
        [XFile(recording.filePath)],
        text: shareText,
        subject: 'Voice Recording - ${recording.keyword ?? 'Audio'}',
      );
    } catch (e) {
      if (e is SharingException) rethrow;
      throw SharingException('Failed to share recording', e);
    }
  }
  
  @override
  Future<void> shareMultipleRecordings(
    List<Recording> recordings, {
    bool createZip = true,
    bool includeMetadata = true,
  }) async {
    try {
      if (recordings.isEmpty) {
        throw SharingException('No recordings to share');
      }
      
      if (createZip) {
        // Create temporary zip file for sharing
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final zipFileName = 'voice_recordings_$timestamp.zip';
        final zipPath = path.join(tempDir.path, zipFileName);
        
        final archive = Archive();
        
        for (final recording in recordings) {
          final sourceFile = File(recording.filePath);
          if (await sourceFile.exists()) {
            final fileBytes = await sourceFile.readAsBytes();
            final fileName = _generateShareFileName(recording);
            
            // Add file to archive
            final archiveFile = ArchiveFile(fileName, fileBytes.length, fileBytes);
            archive.addFile(archiveFile);
          }
        }
        
        // Write zip file
        final zipEncoder = ZipEncoder();
        final zipBytes = zipEncoder.encode(archive);
        if (zipBytes != null) {
          await File(zipPath).writeAsBytes(zipBytes);
          
          // Share the zip file
          String shareText = '${recordings.length} Voice Recordings';
          if (includeMetadata) {
            shareText = _buildMultipleShareText(recordings);
          }
          
          await Share.shareXFiles(
            [XFile(zipPath)],
            text: shareText,
            subject: 'Voice Recordings Archive',
          );
          
          // Clean up temporary zip file after a delay
          Future.delayed(const Duration(seconds: 30), () async {
            try {
              final zipFile = File(zipPath);
              if (await zipFile.exists()) {
                await zipFile.delete();
              }
            } catch (e) {
              print('Warning: Failed to delete temporary zip file: $e');
            }
          });
        }
      } else {
        // Share individual files (limited by platform capabilities)
        final existingFiles = <XFile>[];
        
        for (final recording in recordings) {
          final sourceFile = File(recording.filePath);
          if (await sourceFile.exists()) {
            existingFiles.add(XFile(recording.filePath));
          }
        }
        
        if (existingFiles.isEmpty) {
          throw SharingException('No valid recording files found to share');
        }
        
        String shareText = '${existingFiles.length} Voice Recordings';
        if (includeMetadata) {
          shareText = _buildMultipleShareText(recordings);
        }
        
        await Share.shareXFiles(
          existingFiles,
          text: shareText,
          subject: 'Voice Recordings',
        );
      }
    } catch (e) {
      if (e is SharingException) rethrow;
      throw SharingException('Failed to share multiple recordings', e);
    }
  }
  
  @override
  Future<void> shareToPath(Recording recording, String targetPath) async {
    try {
      final sourceFile = File(recording.filePath);
      if (!await sourceFile.exists()) {
        throw SharingException('Recording file not found: ${recording.filePath}');
      }
      
      final targetFile = File(targetPath);
      final targetDir = targetFile.parent;
      
      // Create target directory if it doesn't exist
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // Copy file to target path
      await sourceFile.copy(targetPath);
    } catch (e) {
      if (e is SharingException) rethrow;
      throw SharingException('Failed to share recording to path', e);
    }
  }
  
  @override
  Future<Directory?> getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // On Android, try to get the Downloads directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Navigate to Downloads folder
          final downloadsPath = path.join(
            directory.parent.parent.parent.parent.path,
            'Download',
          );
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }
        
        // Fallback to app-specific external directory
        return await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        // On iOS, use the Documents directory as downloads aren't directly accessible
        return await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, use Downloads directory if available
        return await getDownloadsDirectory();
      }
    } catch (e) {
      print('Warning: Failed to get downloads directory: $e');
      return null;
    }
  }
  
  @override
  Future<List<SharingOption>> getAvailableSharingOptions() async {
    final options = <SharingOption>[];
    
    // Platform share sheet (always available)
    options.add(const SharingOption(
      id: 'platform_share',
      name: 'Share',
      description: 'Share using system share sheet',
      supportsMultipleFiles: true,
      supportedFormats: ['mp3', 'wav', 'zip'],
    ));
    
    // Export to downloads
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      options.add(const SharingOption(
        id: 'export_downloads',
        name: 'Export to Downloads',
        description: 'Save to device downloads folder',
        supportsMultipleFiles: true,
        supportedFormats: ['mp3', 'wav', 'zip'],
      ));
    }
    
    return options;
  }
  
  @override
  Future<bool> isSharingAvailable() async {
    try {
      // Check if Share.shareXFiles is available
      return true; // share_plus is available on all supported platforms
    } catch (e) {
      return false;
    }
  }
  
  /// Sanitizes a filename by removing invalid characters
  String _sanitizeFilename(String filename) {
    // Remove or replace invalid filename characters
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
  
  /// Builds share text with recording metadata
  String _buildShareText(Recording recording) {
    final buffer = StringBuffer();
    
    if (recording.keyword != null) {
      buffer.writeln('Keyword: ${recording.keyword}');
    }
    
    buffer.writeln('Duration: ${_formatDuration(recording.duration)}');
    buffer.writeln('Recorded: ${_formatDateTime(recording.createdAt)}');
    buffer.writeln('Quality: ${_getQualityText(recording.quality)}');
    buffer.writeln('Size: ${_formatFileSize(recording.fileSize)}');
    
    return buffer.toString().trim();
  }
  
  /// Builds share text for multiple recordings
  String _buildMultipleShareText(List<Recording> recordings) {
    final buffer = StringBuffer();
    
    buffer.writeln('${recordings.length} Voice Recordings');
    
    final totalDuration = recordings.fold<Duration>(
      Duration.zero,
      (sum, recording) => sum + recording.duration,
    );
    
    final totalSize = recordings.fold<double>(
      0.0,
      (sum, recording) => sum + recording.fileSize,
    );
    
    buffer.writeln('Total Duration: ${_formatDuration(totalDuration)}');
    buffer.writeln('Total Size: ${_formatFileSize(totalSize)}');
    
    // List keywords if any
    final keywords = recordings
        .where((r) => r.keyword != null)
        .map((r) => r.keyword!)
        .toSet()
        .toList();
    
    if (keywords.isNotEmpty) {
      buffer.writeln('Keywords: ${keywords.join(', ')}');
    }
    
    return buffer.toString().trim();
  }
  
  /// Generates a filename for sharing based on recording metadata
  String _generateShareFileName(Recording recording) {
    final timestamp = recording.createdAt.millisecondsSinceEpoch;
    final keyword = recording.keyword ?? 'recording';
    final sanitizedKeyword = _sanitizeFilename(keyword);
    final extension = path.extension(recording.filePath);
    
    return '${sanitizedKeyword}_$timestamp$extension';
  }
  
  /// Formats duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Formats date time for display
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
  
  /// Formats file size for display
  String _formatFileSize(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toInt()} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// Gets quality text for display
  String _getQualityText(RecordingQuality quality) {
    switch (quality) {
      case RecordingQuality.low:
        return 'Low';
      case RecordingQuality.medium:
        return 'Medium';
      case RecordingQuality.high:
        return 'High';
    }
  }
}