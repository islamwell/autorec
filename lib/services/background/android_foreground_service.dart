import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Android-specific foreground service for continuous keyword detection
/// Handles background processing with proper notification and battery optimization
class AndroidForegroundService {
  static const MethodChannel _channel = MethodChannel('android_foreground_service');
  
  /// Start the foreground service for keyword detection
  /// Creates a persistent notification and enables background audio processing
  static Future<bool> startKeywordDetectionService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('startKeywordDetection', {
        'notificationTitle': 'Voice Keyword Recorder',
        'notificationText': 'Listening for your keyword...',
        'notificationIcon': 'ic_notification',
        'channelId': 'keyword_detection',
        'channelName': 'Keyword Detection',
        'channelDescription': 'Continuous keyword detection service',
      });
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to start Android foreground service: $e');
      return false;
    }
  }
  
  /// Stop the foreground service
  /// Removes notification and stops background processing
  static Future<bool> stopKeywordDetectionService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('stopKeywordDetection');
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to stop Android foreground service: $e');
      return false;
    }
  }
  
  /// Update the foreground service notification
  /// Changes notification text to reflect current status
  static Future<void> updateNotification({
    required String title,
    required String text,
    String? action,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('updateNotification', {
        'title': title,
        'text': text,
        'action': action,
      });
    } catch (e) {
      print('Failed to update Android notification: $e');
    }
  }
  
  /// Check if the service is currently running
  static Future<bool> isServiceRunning() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('isServiceRunning');
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to check Android service status: $e');
      return false;
    }
  }
  
  /// Request battery optimization exclusion
  /// Helps prevent the system from killing the background service
  static Future<bool> requestBatteryOptimizationExclusion() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('requestBatteryOptimization');
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to request battery optimization exclusion: $e');
      return false;
    }
  }
  
  /// Check if app is excluded from battery optimization
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('isBatteryOptimizationIgnored');
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to check battery optimization status: $e');
      return false;
    }
  }
  
  /// Handle doze mode and app standby
  /// Configures the service to work with Android's power management
  static Future<void> configurePowerManagement() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('configurePowerManagement', {
        'enableWakeLock': true,
        'enablePartialWakeLock': true,
        'requestWhitelistFromDoze': true,
      });
    } catch (e) {
      print('Failed to configure Android power management: $e');
    }
  }
  
  /// Set up service callbacks for Flutter communication
  static void setupServiceCallbacks({
    VoidCallback? onServiceStarted,
    VoidCallback? onServiceStopped,
    Function(String)? onKeywordDetected,
    Function(String)? onError,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onServiceStarted':
          onServiceStarted?.call();
          break;
        case 'onServiceStopped':
          onServiceStopped?.call();
          break;
        case 'onKeywordDetected':
          final keyword = call.arguments as String?;
          if (keyword != null) {
            onKeywordDetected?.call(keyword);
          }
          break;
        case 'onError':
          final error = call.arguments as String?;
          if (error != null) {
            onError?.call(error);
          }
          break;
      }
    });
  }
}