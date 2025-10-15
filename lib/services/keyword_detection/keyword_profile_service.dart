import '../../models/keyword_profile.dart';

/// Abstract interface for managing keyword profiles
abstract class KeywordProfileService {
  /// Save a keyword profile to storage
  /// [profile] the keyword profile to save
  /// Throws [KeywordProfileException] if saving fails
  Future<void> saveProfile(KeywordProfile profile);

  /// Load all saved keyword profiles
  /// Returns list of all saved profiles
  /// Throws [KeywordProfileException] if loading fails
  Future<List<KeywordProfile>> loadAllProfiles();

  /// Load a specific keyword profile by ID
  /// [profileId] the ID of the profile to load
  /// Returns the profile or null if not found
  /// Throws [KeywordProfileException] if loading fails
  Future<KeywordProfile?> loadProfile(String profileId);

  /// Delete a keyword profile and its associated files
  /// [profileId] the ID of the profile to delete
  /// Throws [KeywordProfileException] if deletion fails
  Future<void> deleteProfile(String profileId);

  /// Get the currently active keyword profile
  /// Returns the active profile or null if none is set
  KeywordProfile? get activeProfile;

  /// Set the active keyword profile
  /// [profile] the profile to set as active, or null to clear
  /// Throws [KeywordProfileException] if setting fails
  Future<void> setActiveProfile(KeywordProfile? profile);

  /// Check if a keyword profile exists
  /// [profileId] the ID of the profile to check
  /// Returns true if the profile exists
  Future<bool> profileExists(String profileId);

  /// Update an existing keyword profile
  /// [profile] the updated profile data
  /// Throws [KeywordProfileException] if updating fails
  Future<void> updateProfile(KeywordProfile profile);

  /// Get storage usage for keyword profiles
  /// Returns total size in bytes used by keyword profiles
  Future<int> getStorageUsage();

  /// Cleanup orphaned files (audio files without profiles)
  /// Returns number of files cleaned up
  Future<int> cleanupOrphanedFiles();
}

/// Exception thrown when keyword profile operations fail
class KeywordProfileException implements Exception {
  final String message;
  final dynamic originalError;

  const KeywordProfileException(this.message, [this.originalError]);

  @override
  String toString() => 'KeywordProfileException: $message';
}