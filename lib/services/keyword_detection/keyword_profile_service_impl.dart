import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/keyword_profile.dart';
import 'keyword_profile_service.dart';

/// Implementation of KeywordProfileService for managing keyword profiles
class KeywordProfileServiceImpl implements KeywordProfileService {
  static const String _activeProfileKey = 'active_keyword_profile_id';
  static const String _profilesDirectoryName = 'keywords';
  
  KeywordProfile? _activeProfile;
  List<KeywordProfile>? _cachedProfiles;

  @override
  KeywordProfile? get activeProfile => _activeProfile;

  @override
  Future<void> saveProfile(KeywordProfile profile) async {
    try {
      if (!profile.isValid()) {
        throw KeywordProfileException('Invalid keyword profile data');
      }

      final profilesDir = await _getProfilesDirectory();
      final profileFile = File('${profilesDir.path}/profile_${profile.id}.json');
      
      final profileJson = jsonEncode(profile.toJson());
      await profileFile.writeAsString(profileJson);
      
      // Update cache
      _cachedProfiles = null; // Clear cache to force reload
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to save keyword profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<List<KeywordProfile>> loadAllProfiles() async {
    if (_cachedProfiles != null) {
      return _cachedProfiles!;
    }

    try {
      final profilesDir = await _getProfilesDirectory();
      
      if (!await profilesDir.exists()) {
        _cachedProfiles = [];
        return _cachedProfiles!;
      }

      final profileFiles = await profilesDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final profiles = <KeywordProfile>[];
      
      for (final file in profileFiles) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final profile = KeywordProfile.fromJson(json);
          
          // Verify the audio file still exists
          if (await File(profile.modelPath).exists()) {
            profiles.add(profile);
          } else {
            // Clean up orphaned profile
            await file.delete();
          }
        } catch (e) {
          // Skip corrupted profile files
          print('Warning: Skipping corrupted profile file ${file.path}: $e');
        }
      }

      // Sort by training date (newest first)
      profiles.sort((a, b) => b.trainedAt.compareTo(a.trainedAt));
      
      _cachedProfiles = profiles;
      return profiles;
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to load keyword profiles: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<KeywordProfile?> loadProfile(String profileId) async {
    try {
      final profiles = await loadAllProfiles();
      return profiles.where((p) => p.id == profileId).firstOrNull;
    } catch (e) {
      throw KeywordProfileException(
        'Failed to load keyword profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    try {
      final profile = await loadProfile(profileId);
      if (profile == null) {
        return; // Profile doesn't exist
      }

      // Delete the audio file
      final audioFile = File(profile.modelPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Delete the profile file
      final profilesDir = await _getProfilesDirectory();
      final profileFile = File('${profilesDir.path}/profile_$profileId.json');
      if (await profileFile.exists()) {
        await profileFile.delete();
      }

      // Clear active profile if it was deleted
      if (_activeProfile?.id == profileId) {
        await setActiveProfile(null);
      }

      // Update cache
      _cachedProfiles = null;
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to delete keyword profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> setActiveProfile(KeywordProfile? profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (profile == null) {
        await prefs.remove(_activeProfileKey);
        _activeProfile = null;
      } else {
        // Verify profile exists
        if (!await profileExists(profile.id)) {
          throw KeywordProfileException('Profile does not exist: ${profile.id}');
        }
        
        await prefs.setString(_activeProfileKey, profile.id);
        _activeProfile = profile;
      }
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to set active profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<bool> profileExists(String profileId) async {
    try {
      final profile = await loadProfile(profileId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateProfile(KeywordProfile profile) async {
    try {
      if (!await profileExists(profile.id)) {
        throw KeywordProfileException('Profile does not exist: ${profile.id}');
      }
      
      await saveProfile(profile);
      
      // Update active profile if it's the same one
      if (_activeProfile?.id == profile.id) {
        _activeProfile = profile;
      }
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to update keyword profile: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<int> getStorageUsage() async {
    try {
      final profilesDir = await _getProfilesDirectory();
      
      if (!await profilesDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      
      await for (final entity in profilesDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to calculate storage usage: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<int> cleanupOrphanedFiles() async {
    try {
      final profilesDir = await _getProfilesDirectory();
      
      if (!await profilesDir.exists()) {
        return 0;
      }

      final profiles = await loadAllProfiles();
      final validAudioPaths = profiles.map((p) => p.modelPath).toSet();
      
      int cleanedCount = 0;
      
      await for (final entity in profilesDir.list()) {
        if (entity is File) {
          final path = entity.path;
          
          // Skip profile JSON files
          if (path.endsWith('.json')) {
            continue;
          }
          
          // Check if this audio file is referenced by any profile
          if (!validAudioPaths.contains(path)) {
            await entity.delete();
            cleanedCount++;
          }
        }
      }
      
      return cleanedCount;
      
    } catch (e) {
      throw KeywordProfileException(
        'Failed to cleanup orphaned files: ${e.toString()}',
        e,
      );
    }
  }

  /// Initialize the service by loading the active profile
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeProfileId = prefs.getString(_activeProfileKey);
      
      if (activeProfileId != null) {
        _activeProfile = await loadProfile(activeProfileId);
        
        // Clear invalid active profile
        if (_activeProfile == null) {
          await prefs.remove(_activeProfileKey);
        }
      }
      
    } catch (e) {
      // Don't throw on initialization failure, just log
      print('Warning: Failed to initialize KeywordProfileService: $e');
    }
  }

  /// Get or create the profiles directory
  Future<Directory> _getProfilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final profilesDir = Directory('${appDir.path}/$_profilesDirectoryName');
    
    if (!await profilesDir.exists()) {
      await profilesDir.create(recursive: true);
    }
    
    return profilesDir;
  }
}