import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


import '../../models/recording.dart';
import 'file_storage_service.dart';
import '../audio/audio_conversion_service.dart';
import '../audio/audio_conversion_service_impl.dart';

/// Implementation of FileStorageService for managing recording files and metadata
class FileStorageServiceImpl implements FileStorageService {
  static const String _recordingsKey = 'recordings_metadata';
  static const String _recordingsDir = 'recordings';
  static const String _tempDir = 'temp';
  static const String _backupDir = 'backups';
  
  final Uuid _uuid = const Uuid();
  final AudioConversionService _audioConversionService = AudioConversionServiceImpl();
  
  /// Gets the application documents directory
  Future<Directory> get _appDocumentsDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }
  
  /// Gets the recordings directory, creating it if it doesn't exist
  Future<Directory> get _recordingsDirectory async {
    final appDir = await _appDocumentsDir;
    final recordingsDir = Directory(path.join(appDir.path, _recordingsDir));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir;
  }
  
  /// Gets the temporary directory for processing files
  Future<Directory> get _tempDirectory async {
    final appDir = await _appDocumentsDir;
    final tempDir = Directory(path.join(appDir.path, _tempDir));
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }
  
  /// Gets the backup directory
  Future<Directory> get _backupDirectory async {
    final appDir = await _appDocumentsDir;
    final backupDir = Directory(path.join(appDir.path, _backupDir));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  @override
  Future<String> saveRecording(String tempPath, Map<String, dynamic> metadata) async {
    try {
      final tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw FileStorageException('Temporary file does not exist: $tempPath');
      }

      // Generate unique ID and create permanent file path
      final recordingId = _uuid.v4();
      final recordingsDir = await _recordingsDirectory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Extract metadata for conversion configuration
      final quality = _parseRecordingQuality(metadata['quality'] as String?);
      final shouldCompress = metadata['compress'] as bool? ?? true;
      
      String permanentPath;
      double fileSize;
      
      if (shouldCompress) {
        // Convert to MP3 for storage efficiency
        final conversionConfig = _getConversionConfig(quality);
        final mp3FileName = '${timestamp}_$recordingId.mp3';
        final mp3Path = path.join(recordingsDir.path, mp3FileName);
        
        // Convert audio to MP3
        permanentPath = await _audioConversionService.convertAudio(
          tempPath,
          mp3Path,
          conversionConfig,
        );
        
        // Get compressed file size
        final compressedFile = File(permanentPath);
        final fileStat = await compressedFile.stat();
        fileSize = fileStat.size.toDouble();
      } else {
        // Save as original WAV format
        final wavFileName = '${timestamp}_$recordingId.wav';
        permanentPath = path.join(recordingsDir.path, wavFileName);
        final permanentFile = await tempFile.copy(permanentPath);
        
        // Get file stats
        final fileStat = await permanentFile.stat();
        fileSize = fileStat.size.toDouble();
      }
      
      // Extract other metadata
      final keyword = metadata['keyword'] as String?;
      final duration = Duration(milliseconds: metadata['duration'] as int? ?? 0);
      
      // Create Recording object
      final recording = Recording(
        id: recordingId,
        filePath: permanentPath,
        createdAt: DateTime.now(),
        duration: duration,
        keyword: keyword,
        fileSize: fileSize,
        quality: quality,
      );
      
      // Validate recording
      if (!recording.isValid()) {
        throw FileStorageException('Invalid recording data');
      }
      
      // Save metadata
      await _saveRecordingMetadata(recording);
      
      // Clean up temporary file
      try {
        await tempFile.delete();
      } catch (e) {
        // Log but don't fail if temp cleanup fails
        print('Warning: Failed to delete temporary file: $e');
      }
      
      return permanentPath;
    } catch (e) {
      throw FileStorageException('Failed to save recording', e);
    }
  }

  @override
  Future<List<Recording>> getAllRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordingsJson = prefs.getStringList(_recordingsKey) ?? [];
      
      final recordings = <Recording>[];
      for (final recordingJson in recordingsJson) {
        try {
          final recordingMap = json.decode(recordingJson) as Map<String, dynamic>;
          final recording = Recording.fromJson(recordingMap);
          
          // Verify file still exists
          final file = File(recording.filePath);
          if (await file.exists()) {
            recordings.add(recording);
          } else {
            // Remove metadata for missing files
            await _removeRecordingMetadata(recording.id);
          }
        } catch (e) {
          print('Warning: Failed to parse recording metadata: $e');
        }
      }
      
      // Sort by creation date (newest first)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return recordings;
    } catch (e) {
      throw FileStorageException('Failed to retrieve recordings', e);
    }
  }

  @override
  Future<Recording?> getRecording(String id) async {
    try {
      final recordings = await getAllRecordings();
      return recordings.where((r) => r.id == id).firstOrNull;
    } catch (e) {
      throw FileStorageException('Failed to get recording', e);
    }
  }

  @override
  Future<void> deleteRecording(String id) async {
    try {
      final recording = await getRecording(id);
      if (recording == null) {
        throw FileStorageException('Recording not found: $id');
      }
      
      // Delete the file
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove metadata
      await _removeRecordingMetadata(id);
    } catch (e) {
      throw FileStorageException('Failed to delete recording', e);
    }
  }

  @override
  Future<String> exportToMp3(String recordingId) async {
    try {
      final recording = await getRecording(recordingId);
      if (recording == null) {
        throw FileStorageException('Recording not found: $recordingId');
      }
      
      final sourceFile = File(recording.filePath);
      if (!await sourceFile.exists()) {
        throw FileStorageException('Recording file not found: ${recording.filePath}');
      }
      
      // Create export directory in downloads
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw FileStorageException('Downloads directory not available');
      }
      
      final exportDir = Directory(path.join(downloadsDir.path, 'VoiceRecordings'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      // Generate export filename
      final timestamp = recording.createdAt.millisecondsSinceEpoch;
      final keyword = recording.keyword ?? 'recording';
      final exportFileName = '${keyword}_$timestamp.mp3';
      final exportPath = path.join(exportDir.path, exportFileName);
      
      // Check if source is already MP3
      final sourceExtension = path.extension(recording.filePath).toLowerCase();
      if (sourceExtension == '.mp3') {
        // Just copy the MP3 file
        await sourceFile.copy(exportPath);
      } else {
        // Convert to MP3 for export
        final conversionConfig = AudioConversionConfig.voiceOptimized;
        await _audioConversionService.convertAudio(
          recording.filePath,
          exportPath,
          conversionConfig,
        );
      }
      
      return exportPath;
    } catch (e) {
      throw FileStorageException('Failed to export recording', e);
    }
  }

  @override
  Future<int> getTotalStorageUsed() async {
    try {
      final recordingsDir = await _recordingsDirectory;
      int totalSize = 0;
      
      await for (final entity in recordingsDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      throw FileStorageException('Failed to calculate storage usage', e);
    }
  }

  @override
  Future<int> getAvailableStorage() async {
    try {
      // Since disk_space dependency was removed, return a reasonable default
      // In a real implementation, you could use platform channels or other methods
      return 1024 * 1024 * 1024; // 1GB default
    } catch (e) {
      throw FileStorageException('Failed to get available storage', e);
    }
  }

  @override
  Future<void> cleanup({int? olderThanDays}) async {
    try {
      final recordings = await getAllRecordings();
      final cutoffDate = olderThanDays != null 
          ? DateTime.now().subtract(Duration(days: olderThanDays))
          : null;
      
      for (final recording in recordings) {
        if (cutoffDate != null && recording.createdAt.isAfter(cutoffDate)) {
          continue;
        }
        
        await deleteRecording(recording.id);
      }
      
      // Clean up temporary directory
      final tempDir = await _tempDirectory;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            await entity.delete();
          } catch (e) {
            print('Warning: Failed to delete temp file: $e');
          }
        }
      }
    } catch (e) {
      throw FileStorageException('Failed to cleanup files', e);
    }
  }

  @override
  Future<String> createBackup() async {
    try {
      final recordings = await getAllRecordings();
      final backupData = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'recordings': recordings.map((r) => r.toJson()).toList(),
      };
      
      final backupDir = await _backupDirectory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'recordings_backup_$timestamp.json';
      final backupPath = path.join(backupDir.path, backupFileName);
      
      final backupFile = File(backupPath);
      await backupFile.writeAsString(json.encode(backupData));
      
      return backupPath;
    } catch (e) {
      throw FileStorageException('Failed to create backup', e);
    }
  }

  @override
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw FileStorageException('Backup file not found: $backupPath');
      }
      
      final backupContent = await backupFile.readAsString();
      final backupData = json.decode(backupContent) as Map<String, dynamic>;
      
      final recordingsData = backupData['recordings'] as List<dynamic>;
      for (final recordingData in recordingsData) {
        try {
          final recording = Recording.fromJson(recordingData as Map<String, dynamic>);
          await _saveRecordingMetadata(recording);
        } catch (e) {
          print('Warning: Failed to restore recording metadata: $e');
        }
      }
    } catch (e) {
      throw FileStorageException('Failed to restore from backup', e);
    }
  }
  
  /// Saves recording metadata to SharedPreferences
  Future<void> _saveRecordingMetadata(Recording recording) async {
    final prefs = await SharedPreferences.getInstance();
    final recordingsJson = prefs.getStringList(_recordingsKey) ?? [];
    
    // Remove existing entry if it exists
    recordingsJson.removeWhere((json) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return data['id'] == recording.id;
      } catch (e) {
        return false;
      }
    });
    
    // Add new entry
    recordingsJson.add(json.encode(recording.toJson()));
    
    await prefs.setStringList(_recordingsKey, recordingsJson);
  }
  
  /// Removes recording metadata from SharedPreferences
  Future<void> _removeRecordingMetadata(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final recordingsJson = prefs.getStringList(_recordingsKey) ?? [];
    
    recordingsJson.removeWhere((json) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return data['id'] == id;
      } catch (e) {
        return false;
      }
    });
    
    await prefs.setStringList(_recordingsKey, recordingsJson);
  }
  
  /// Parses recording quality from string
  RecordingQuality _parseRecordingQuality(String? qualityStr) {
    switch (qualityStr?.toLowerCase()) {
      case 'low':
        return RecordingQuality.low;
      case 'high':
        return RecordingQuality.high;
      case 'medium':
      default:
        return RecordingQuality.medium;
    }
  }
  
  /// Gets audio conversion configuration based on recording quality
  AudioConversionConfig _getConversionConfig(RecordingQuality quality) {
    switch (quality) {
      case RecordingQuality.low:
        return AudioConversionConfig.maxCompression;
      case RecordingQuality.high:
        return AudioConversionConfig.highQuality;
      case RecordingQuality.medium:
        return AudioConversionConfig.voiceOptimized;
    }
  }
}