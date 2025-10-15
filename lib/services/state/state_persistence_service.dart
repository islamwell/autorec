import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and restoring app state across sessions
abstract class StatePersistenceService {
  /// Save state data with a key
  Future<void> saveState(String key, Map<String, dynamic> data);
  
  /// Load state data by key
  Future<Map<String, dynamic>?> loadState(String key);
  
  /// Remove state data by key
  Future<void> removeState(String key);
  
  /// Clear all persisted state
  Future<void> clearAllState();
  
  /// Check if state exists for a key
  Future<bool> hasState(String key);
  
  /// Get all state keys
  Future<List<String>> getAllStateKeys();
}

/// Implementation of state persistence using SharedPreferences
class StatePersistenceServiceImpl implements StatePersistenceService {
  static const String _statePrefix = 'app_state_';
  
  @override
  Future<void> saveState(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateKey = _statePrefix + key;
      final jsonString = json.encode(data);
      await prefs.setString(stateKey, jsonString);
    } catch (e) {
      throw StateException('Failed to save state for key $key: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> loadState(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateKey = _statePrefix + key;
      final jsonString = prefs.getString(stateKey);
      
      if (jsonString == null) {
        return null;
      }
      
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw StateException('Failed to load state for key $key: ${e.toString()}');
    }
  }
  
  @override
  Future<void> removeState(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateKey = _statePrefix + key;
      await prefs.remove(stateKey);
    } catch (e) {
      throw StateException('Failed to remove state for key $key: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearAllState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final stateKeys = keys.where((key) => key.startsWith(_statePrefix));
      
      for (final key in stateKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw StateException('Failed to clear all state: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> hasState(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateKey = _statePrefix + key;
      return prefs.containsKey(stateKey);
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<String>> getAllStateKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_statePrefix))
          .map((key) => key.substring(_statePrefix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Exception thrown when state persistence operations fail
class StateException implements Exception {
  final String message;
  
  const StateException(this.message);
  
  @override
  String toString() => 'StateException: $message';
}