import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

import '../../models/recording.dart';
import 'recording_manager_service.dart';
import 'file_storage_service.dart';

/// Implementation of RecordingManagerService
class RecordingManagerServiceImpl implements RecordingManagerService {
  final FileStorageService _fileStorageService;
  
  RecordingManagerServiceImpl(this._fileStorageService);
  
  @override
  Future<List<Recording>> getRecordings({
    RecordingFilter? filter,
    RecordingSortBy sortBy = RecordingSortBy.dateCreated,
    SortOrder sortOrder = SortOrder.descending,
    int? limit,
    int? offset,
  }) async {
    try {
      // Get all recordings
      var recordings = await _fileStorageService.getAllRecordings();
      
      // Apply filter
      if (filter != null) {
        recordings = _applyFilter(recordings, filter);
      }
      
      // Apply sorting
      recordings = _applySorting(recordings, sortBy, sortOrder);
      
      // Apply pagination
      if (offset != null && offset > 0) {
        recordings = recordings.skip(offset).toList();
      }
      
      if (limit != null && limit > 0) {
        recordings = recordings.take(limit).toList();
      }
      
      return recordings;
    } catch (e) {
      throw Exception('Failed to get recordings: $e');
    }
  }
  
  @override
  Future<Recording?> getRecording(String id) async {
    return await _fileStorageService.getRecording(id);
  }
  
  @override
  Future<Recording> createRecording(String tempPath, Map<String, dynamic> metadata) async {
    try {
      final savedPath = await _fileStorageService.saveRecording(tempPath, metadata);
      
      // Extract recording ID from the saved path to retrieve the full recording
      final recordings = await _fileStorageService.getAllRecordings();
      final recording = recordings.firstWhere(
        (r) => r.filePath == savedPath,
        orElse: () => throw Exception('Failed to find created recording'),
      );
      
      return recording;
    } catch (e) {
      throw Exception('Failed to create recording: $e');
    }
  }
  
  @override
  Future<Recording> updateRecording(String id, Map<String, dynamic> updates) async {
    try {
      final recording = await _fileStorageService.getRecording(id);
      if (recording == null) {
        throw Exception('Recording not found: $id');
      }
      
      // Create updated recording
      final updatedRecording = recording.copyWith(
        keyword: updates['keyword'] as String? ?? recording.keyword,
        quality: updates['quality'] as RecordingQuality? ?? recording.quality,
      );
      
      // Note: For a full implementation, we would need to update the metadata storage
      // This is a simplified version that returns the updated object
      // In practice, you'd need to update the SharedPreferences storage
      
      return updatedRecording;
    } catch (e) {
      throw Exception('Failed to update recording: $e');
    }
  }
  
  @override
  Future<void> deleteRecording(String id) async {
    await _fileStorageService.deleteRecording(id);
  }
  
  @override
  Future<int> deleteMultipleRecordings(List<String> ids) async {
    int deletedCount = 0;
    
    for (final id in ids) {
      try {
        await _fileStorageService.deleteRecording(id);
        deletedCount++;
      } catch (e) {
        // Log error but continue with other deletions
        print('Failed to delete recording $id: $e');
      }
    }
    
    return deletedCount;
  }
  
  @override
  Future<RecordingStatistics> getStatistics({RecordingFilter? filter}) async {
    try {
      var recordings = await _fileStorageService.getAllRecordings();
      
      // Apply filter if provided
      if (filter != null) {
        recordings = _applyFilter(recordings, filter);
      }
      
      if (recordings.isEmpty) {
        return const RecordingStatistics(
          totalRecordings: 0,
          totalDuration: Duration.zero,
          totalFileSize: 0,
          averageFileSize: 0,
          averageDuration: Duration.zero,
          qualityDistribution: {},
          keywordDistribution: {},
        );
      }
      
      // Calculate statistics
      final totalRecordings = recordings.length;
      final totalDuration = recordings.fold<Duration>(
        Duration.zero,
        (sum, recording) => sum + recording.duration,
      );
      final totalFileSize = recordings.fold<double>(
        0.0,
        (sum, recording) => sum + recording.fileSize,
      );
      
      final averageFileSize = totalFileSize / totalRecordings;
      final averageDuration = Duration(
        milliseconds: (totalDuration.inMilliseconds / totalRecordings).round(),
      );
      
      // Quality distribution
      final qualityDistribution = <RecordingQuality, int>{};
      for (final recording in recordings) {
        qualityDistribution[recording.quality] = 
            (qualityDistribution[recording.quality] ?? 0) + 1;
      }
      
      // Keyword distribution
      final keywordDistribution = <String, int>{};
      for (final recording in recordings) {
        final keyword = recording.keyword ?? 'No keyword';
        keywordDistribution[keyword] = (keywordDistribution[keyword] ?? 0) + 1;
      }
      
      // Date range
      recordings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final oldestRecording = recordings.first.createdAt;
      final newestRecording = recordings.last.createdAt;
      
      return RecordingStatistics(
        totalRecordings: totalRecordings,
        totalDuration: totalDuration,
        totalFileSize: totalFileSize,
        averageFileSize: averageFileSize,
        averageDuration: averageDuration,
        qualityDistribution: qualityDistribution,
        keywordDistribution: keywordDistribution,
        oldestRecording: oldestRecording,
        newestRecording: newestRecording,
      );
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
  
  @override
  Future<StorageInfo> getStorageInfo() async {
    try {
      final totalStorageUsed = await _fileStorageService.getTotalStorageUsed();
      final availableStorage = await _fileStorageService.getAvailableStorage();
      final totalStorage = totalStorageUsed + availableStorage;
      
      final usagePercentage = totalStorage > 0 
          ? (totalStorageUsed / totalStorage) * 100 
          : 0.0;
      
      final availablePercentage = 100 - usagePercentage;
      final isLowStorage = availablePercentage < 10;
      final isCriticalStorage = availablePercentage < 5;
      
      return StorageInfo(
        totalStorageUsed: totalStorageUsed,
        availableStorage: availableStorage,
        totalStorage: totalStorage,
        usagePercentage: usagePercentage,
        isLowStorage: isLowStorage,
        isCriticalStorage: isCriticalStorage,
      );
    } catch (e) {
      throw Exception('Failed to get storage info: $e');
    }
  }
  
  @override
  Future<List<Recording>> searchRecordings(String query, {int? limit}) async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      final queryLower = query.toLowerCase();
      
      final matchingRecordings = recordings.where((recording) {
        // Search in keyword
        if (recording.keyword?.toLowerCase().contains(queryLower) == true) {
          return true;
        }
        
        // Search in file name
        final fileName = path.basenameWithoutExtension(recording.filePath);
        if (fileName.toLowerCase().contains(queryLower)) {
          return true;
        }
        
        return false;
      }).toList();
      
      // Sort by relevance (exact matches first, then partial matches)
      matchingRecordings.sort((a, b) {
        final aKeyword = a.keyword?.toLowerCase() ?? '';
        final bKeyword = b.keyword?.toLowerCase() ?? '';
        
        // Exact keyword matches first
        if (aKeyword == queryLower && bKeyword != queryLower) return -1;
        if (bKeyword == queryLower && aKeyword != queryLower) return 1;
        
        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
      
      if (limit != null && limit > 0) {
        return matchingRecordings.take(limit).toList();
      }
      
      return matchingRecordings;
    } catch (e) {
      throw Exception('Failed to search recordings: $e');
    }
  }
  
  @override
  Future<Map<String, List<Recording>>> getRecordingsByKeyword() async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      final groupedRecordings = <String, List<Recording>>{};
      
      for (final recording in recordings) {
        final keyword = recording.keyword ?? 'No keyword';
        groupedRecordings.putIfAbsent(keyword, () => []).add(recording);
      }
      
      // Sort recordings within each group by date (newest first)
      for (final recordings in groupedRecordings.values) {
        recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      return groupedRecordings;
    } catch (e) {
      throw Exception('Failed to group recordings by keyword: $e');
    }
  }
  
  @override
  Future<Map<DateTime, List<Recording>>> getRecordingsByDate() async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      final groupedRecordings = <DateTime, List<Recording>>{};
      
      for (final recording in recordings) {
        // Group by date (ignoring time)
        final date = DateTime(
          recording.createdAt.year,
          recording.createdAt.month,
          recording.createdAt.day,
        );
        groupedRecordings.putIfAbsent(date, () => []).add(recording);
      }
      
      // Sort recordings within each group by time (newest first)
      for (final recordings in groupedRecordings.values) {
        recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      return groupedRecordings;
    } catch (e) {
      throw Exception('Failed to group recordings by date: $e');
    }
  }
  
  @override
  Future<String> exportRecording(String id, {String format = 'mp3'}) async {
    try {
      if (format.toLowerCase() == 'mp3') {
        return await _fileStorageService.exportToMp3(id);
      } else {
        // For other formats, we'd need to implement additional conversion
        throw Exception('Export format not supported: $format');
      }
    } catch (e) {
      throw Exception('Failed to export recording: $e');
    }
  }
  
  @override
  Future<String> exportMultipleRecordings(List<String> ids, {String format = 'mp3'}) async {
    // This would require implementing zip file creation
    // For now, throw an exception indicating it's not implemented
    throw Exception('Multiple recording export not implemented yet');
  }
  
  @override
  Future<int> cleanupOldRecordings({int? olderThanDays, int? keepMinimum}) async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      
      if (recordings.isEmpty) return 0;
      
      // Sort by date (oldest first)
      recordings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      final recordingsToDelete = <Recording>[];
      
      if (olderThanDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
        recordingsToDelete.addAll(
          recordings.where((r) => r.createdAt.isBefore(cutoffDate)),
        );
      }
      
      // Ensure we keep minimum number of recordings
      if (keepMinimum != null) {
        final totalRecordings = recordings.length;
        final maxToDelete = max(0, totalRecordings - keepMinimum);
        
        if (recordingsToDelete.length > maxToDelete) {
          // Keep the newest recordings that would be deleted
          recordingsToDelete.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          recordingsToDelete.removeRange(0, recordingsToDelete.length - maxToDelete);
        }
      }
      
      // Delete the recordings
      int deletedCount = 0;
      for (final recording in recordingsToDelete) {
        try {
          await _fileStorageService.deleteRecording(recording.id);
          deletedCount++;
        } catch (e) {
          print('Failed to delete recording ${recording.id}: $e');
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw Exception('Failed to cleanup old recordings: $e');
    }
  }
  
  @override
  Future<String> createBackup() async {
    return await _fileStorageService.createBackup();
  }
  
  @override
  Future<void> restoreFromBackup(String backupPath) async {
    await _fileStorageService.restoreFromBackup(backupPath);
  }
  
  @override
  Future<bool> validateRecording(String id) async {
    try {
      final recording = await _fileStorageService.getRecording(id);
      if (recording == null) return false;
      
      final file = File(recording.filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<String>> validateAllRecordings() async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      final invalidRecordings = <String>[];
      
      for (final recording in recordings) {
        final isValid = await validateRecording(recording.id);
        if (!isValid) {
          invalidRecordings.add(recording.id);
        }
      }
      
      return invalidRecordings;
    } catch (e) {
      throw Exception('Failed to validate recordings: $e');
    }
  }
  
  @override
  Future<List<List<Recording>>> findDuplicateRecordings() async {
    try {
      final recordings = await _fileStorageService.getAllRecordings();
      final duplicateGroups = <List<Recording>>[];
      
      // Group by potential duplicate criteria
      final groupedBySize = <double, List<Recording>>{};
      
      for (final recording in recordings) {
        groupedBySize.putIfAbsent(recording.fileSize, () => []).add(recording);
      }
      
      // Find groups with multiple recordings of same size
      for (final group in groupedBySize.values) {
        if (group.length > 1) {
          // Further filter by duration similarity
          final durationGroups = <int, List<Recording>>{};
          
          for (final recording in group) {
            final durationKey = (recording.duration.inSeconds / 5).round() * 5; // Group by 5-second intervals
            durationGroups.putIfAbsent(durationKey, () => []).add(recording);
          }
          
          for (final durationGroup in durationGroups.values) {
            if (durationGroup.length > 1) {
              duplicateGroups.add(durationGroup);
            }
          }
        }
      }
      
      return duplicateGroups;
    } catch (e) {
      throw Exception('Failed to find duplicate recordings: $e');
    }
  }
  
  /// Applies filter to list of recordings
  List<Recording> _applyFilter(List<Recording> recordings, RecordingFilter filter) {
    return recordings.where((recording) {
      // Filter by keyword
      if (filter.keyword != null) {
        final keyword = recording.keyword?.toLowerCase() ?? '';
        if (!keyword.contains(filter.keyword!.toLowerCase())) {
          return false;
        }
      }
      
      // Filter by date range
      if (filter.startDate != null && recording.createdAt.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && recording.createdAt.isAfter(filter.endDate!)) {
        return false;
      }
      
      // Filter by duration range
      if (filter.minDuration != null && recording.duration < filter.minDuration!) {
        return false;
      }
      if (filter.maxDuration != null && recording.duration > filter.maxDuration!) {
        return false;
      }
      
      // Filter by quality
      if (filter.quality != null && recording.quality != filter.quality!) {
        return false;
      }
      
      // Filter by file size range
      if (filter.minFileSize != null && recording.fileSize < filter.minFileSize!) {
        return false;
      }
      if (filter.maxFileSize != null && recording.fileSize > filter.maxFileSize!) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  /// Applies sorting to list of recordings
  List<Recording> _applySorting(
    List<Recording> recordings,
    RecordingSortBy sortBy,
    SortOrder sortOrder,
  ) {
    recordings.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case RecordingSortBy.dateCreated:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case RecordingSortBy.duration:
          comparison = a.duration.compareTo(b.duration);
          break;
        case RecordingSortBy.fileSize:
          comparison = a.fileSize.compareTo(b.fileSize);
          break;
        case RecordingSortBy.keyword:
          final aKeyword = a.keyword ?? '';
          final bKeyword = b.keyword ?? '';
          comparison = aKeyword.compareTo(bKeyword);
          break;
        case RecordingSortBy.alphabetical:
          final aName = path.basenameWithoutExtension(a.filePath);
          final bName = path.basenameWithoutExtension(b.filePath);
          comparison = aName.compareTo(bName);
          break;
      }
      
      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    return recordings;
  }
}