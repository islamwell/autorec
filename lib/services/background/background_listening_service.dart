import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';
import '../keyword_detection/keyword_detection_service.dart';
import '../service_locator.dart';
import '../../models/app_settings.dart';

/// Service for managing background keyword listening with platform-specific optimizations
abstract class BackgroundListeningService {
  /// Starts background listening for keywords
  Future<void> startBackgroundListening();
  
  /// Stops background listening
  Future<void> stopBackgroundListening();
  
  /// Checks if background listening is currently active
  bool get isBackgroundListening;
  
  /// Stream that emits battery level changes
  Stream<int> get batteryLevelStream;
  
  /// Stream that emits power save mode status
  Stream<bool> get powerSaveModeStream;
  
  /// Configures background listening settings
  Future<void> configureBackgroundSettings(AppSettings settings);
  
  /// Handles platform-specific background mode setup
  Future<void> setupPlatformBackgroundMode();
  
  /// Checks if background listening is supported on this device
  Future<bool> isBackgroundListeningSupported();
  
  /// Gets background listening statistics
  Map<String, dynamic> getBackgroundListeningStats();
  
  /// Disposes of background service resources
  Future<void> dispose();
}

/// Exception thrown when background listening operations fail
class BackgroundListeningException implements Exception {
  final String message;
  final dynamic originalError;

  const BackgroundListeningException(this.message, [this.originalError]);

  @override
  String toString() => 'BackgroundListeningException: $message';
}

/// Background task identifiers
class BackgroundTasks {
  static const String keywordListening = 'keyword_listening_task';
  static const String batteryMonitoring = 'battery_monitoring_task';
  static const String powerSaveCheck = 'power_save_check_task';
}

/// Background service configuration
class BackgroundConfig {
  static const int batteryLowThreshold = 15; // 15% battery
  static const int batteryCheckIntervalMinutes = 5;
  static const int keywordListeningIntervalSeconds = 30;
  static const Duration maxBackgroundDuration = Duration(hours: 8);
}