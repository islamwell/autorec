import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Simple foreground service to keep app running when phone is locked
/// This allows keyword detection to continue in the background
class SimpleForegroundService {
  static final SimpleForegroundService _instance = SimpleForegroundService._internal();
  factory SimpleForegroundService() => _instance;
  SimpleForegroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isRunning = false;

  /// Check if service is running
  bool get isRunning => _isRunning;

  /// Initialize the foreground service
  Future<void> initialize() async {
    try {
      await _service.configure(
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
        androidConfiguration: AndroidConfiguration(
          autoStart: false,
          onStart: _onStart,
          isForegroundMode: true,
          autoStartOnBoot: false,
          notificationChannelId: 'keyword_detection_foreground',
          initialNotificationTitle: 'Voice Keyword Recorder',
          initialNotificationContent: 'Listening for your keyword...',
          foregroundServiceNotificationId: 999,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing foreground service: $e');
    }
  }

  /// Start the foreground service
  Future<bool> start() async {
    try {
      if (_isRunning) {
        if (kDebugMode) debugPrint('Foreground service already running');
        return true;
      }

      final started = await _service.startService();
      if (started) {
        _isRunning = true;
        if (kDebugMode) debugPrint('Foreground service started successfully');
      }
      return started;
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting foreground service: $e');
      return false;
    }
  }

  /// Stop the foreground service
  Future<bool> stop() async {
    try {
      if (!_isRunning) {
        if (kDebugMode) debugPrint('Foreground service not running');
        return true;
      }

      _service.invoke('stopService');
      _isRunning = false;
      if (kDebugMode) debugPrint('Foreground service stopped successfully');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error stopping foreground service: $e');
      return false;
    }
  }

  /// Update notification text
  Future<void> updateNotification({
    required String title,
    required String content,
  }) async {
    try {
      _service.invoke('updateNotification', {
        'title': title,
        'content': content,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating notification: $e');
    }
  }

  /// Service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // For Android, set as foreground service
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    // Handle stop service request
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Handle notification update
    service.on('updateNotification').listen((event) {
      if (service is AndroidServiceInstance) {
        final data = event as Map<String, dynamic>?;
        if (data != null) {
          service.setForegroundNotificationInfo(
            title: data['title'] as String? ?? 'Voice Keyword Recorder',
            content: data['content'] as String? ?? 'Listening for your keyword...',
          );
        }
      }
    });

    // Keep service alive - just log periodically
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (kDebugMode) debugPrint('Background service still running...');
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    // iOS has different background handling
    // This is called when app goes to background
    return true;
  }
}
