import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

/// Implementation of NotificationService using flutter_local_notifications
class NotificationServiceImpl implements NotificationService {
  static const String _channelId = 'voice_recorder_channel';
  static const String _channelName = 'Voice Recorder';
  static const String _channelDescription = 'Notifications for voice recording events';
  
  static const int _autoStopNotificationId = 1;
  static const int _recordingStartedNotificationId = 2;
  static const int _recordingStoppedNotificationId = 3;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      _isInitialized = true;
    } catch (e) {
      throw NotificationException(
        'Failed to initialize notifications: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await initialize();

      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }

      return true; // Assume granted for other platforms
    } catch (e) {
      throw NotificationException(
        'Failed to request notification permissions: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> showAutoStopNotification({
    required String recordingPath,
    required Duration recordingDuration,
  }) async {
    try {
      await initialize();

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1A237E),
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final durationText = _formatDuration(recordingDuration);
      
      await _notifications.show(
        _autoStopNotificationId,
        'Recording Auto-Stopped',
        'Your recording ($durationText) has been automatically saved.',
        notificationDetails,
      );
    } catch (e) {
      throw NotificationException(
        'Failed to show auto-stop notification: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> showRecordingStartedNotification() async {
    try {
      await initialize();

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1A237E),
        ongoing: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _recordingStartedNotificationId,
        'Recording in Progress',
        'Voice recording is active. Tap to return to app.',
        notificationDetails,
      );
    } catch (e) {
      throw NotificationException(
        'Failed to show recording started notification: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> showRecordingStoppedNotification({
    required Duration recordingDuration,
  }) async {
    try {
      await initialize();

      // Cancel the ongoing recording notification first
      await _notifications.cancel(_recordingStartedNotificationId);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1A237E),
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final durationText = _formatDuration(recordingDuration);
      
      await _notifications.show(
        _recordingStoppedNotificationId,
        'Recording Saved',
        'Your recording ($durationText) has been saved successfully.',
        notificationDetails,
      );
    } catch (e) {
      throw NotificationException(
        'Failed to show recording stopped notification: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw NotificationException(
        'Failed to cancel notifications: ${e.toString()}',
        e,
      );
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      return '${minutes}m ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Future<void> dispose() async {
    await cancelAllNotifications();
    _isInitialized = false;
  }
}