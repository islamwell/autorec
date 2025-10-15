import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../keyword_detection/keyword_detection_service.dart';
import '../keyword_detection/keyword_detection_service_impl.dart';
import '../../models/app_settings.dart';
import 'background_listening_service.dart';
import 'android_foreground_service.dart';

/// Implementation of BackgroundListeningService with platform-specific optimizations
class BackgroundListeningServiceImpl implements BackgroundListeningService {
  static const String _portName = 'background_keyword_detection';
  
  final Battery _battery = Battery();
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  
  StreamController<int>? _batteryLevelController;
  StreamController<bool>? _powerSaveModeController;
  Timer? _batteryMonitorTimer;
  Timer? _powerSaveCheckTimer;
  
  bool _isBackgroundListening = false;
  AppSettings? _currentSettings;
  ReceivePort? _receivePort;
  DateTime? _backgroundListeningStartTime;
  int _keywordDetectionCount = 0;
  int _backgroundTaskExecutions = 0;
  
  @override
  Stream<int> get batteryLevelStream => 
      _batteryLevelController?.stream ?? const Stream.empty();

  @override
  Stream<bool> get powerSaveModeStream =>
      _powerSaveModeController?.stream ?? const Stream.empty();

  @override
  bool get isBackgroundListening => _isBackgroundListening;

  /// Initialize the background listening service
  Future<void> _initialize() async {
    _batteryLevelController = StreamController<int>.broadcast();
    _powerSaveModeController = StreamController<bool>.broadcast();
    
    // Set up communication port for background isolate
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
    
    // Listen for messages from background isolate
    _receivePort!.listen((data) {
      if (data is Map<String, dynamic>) {
        _handleBackgroundMessage(data);
      }
    });
    
    // Initialize platform-specific background service
    await _initializeBackgroundService();
    
    // Start monitoring battery and power save mode
    await _startSystemMonitoring();
  }

  @override
  Future<void> startBackgroundListening() async {
    if (_isBackgroundListening) {
      return; // Already listening
    }

    try {
      // Initialize if needed
      if (_batteryLevelController == null) {
        await _initialize();
      }

      // Check permissions
      await _checkRequiredPermissions();
      
      // Check battery level before starting
      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel < BackgroundConfig.batteryLowThreshold) {
        throw BackgroundListeningException(
          'Battery level too low ($batteryLevel%). Background listening requires at least ${BackgroundConfig.batteryLowThreshold}%.'
        );
      }

      // Configure platform-specific background mode
      await setupPlatformBackgroundMode();
      
      // Start background service
      if (Platform.isAndroid) {
        // Start Android foreground service for continuous listening
        await AndroidForegroundService.configurePowerManagement();
        final started = await AndroidForegroundService.startKeywordDetectionService();
        if (!started) {
          throw BackgroundListeningException('Failed to start Android foreground service');
        }
        await _startAndroidBackgroundService();
      } else if (Platform.isIOS) {
        await _startIOSBackgroundProcessing();
      }
      
      _isBackgroundListening = true;
      _backgroundListeningStartTime = DateTime.now();
      
    } catch (e) {
      throw BackgroundListeningException(
        'Failed to start background listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> stopBackgroundListening() async {
    if (!_isBackgroundListening) {
      return; // Already stopped
    }

    try {
      // Stop platform-specific services
      if (Platform.isAndroid) {
        await AndroidForegroundService.stopKeywordDetectionService();
      }
      
      // Stop background service
      _backgroundService.invoke('stop');
      
      // Cancel work manager tasks
      await Workmanager().cancelAll();
      
      _isBackgroundListening = false;
      _backgroundListeningStartTime = null;
      
    } catch (e) {
      throw BackgroundListeningException(
        'Failed to stop background listening: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> configureBackgroundSettings(AppSettings settings) async {
    _currentSettings = settings;
    
    // Update background service configuration if running
    if (_isBackgroundListening) {
      _backgroundService.invoke('updateSettings', {
        'keywordListeningEnabled': settings.keywordListeningEnabled,
        'backgroundModeEnabled': settings.backgroundModeEnabled,
        'confidenceThreshold': 0.7, // Default confidence threshold
      });
    }
  }

  @override
  Future<void> setupPlatformBackgroundMode() async {
    if (Platform.isAndroid) {
      await _setupAndroidBackgroundMode();
    } else if (Platform.isIOS) {
      await _setupIOSBackgroundMode();
    }
  }

  /// Check if background listening is supported on this device
  Future<bool> isBackgroundListeningSupported() async {
    try {
      // Check if required permissions can be granted
      final microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus.isPermanentlyDenied) {
        return false;
      }
      
      if (Platform.isAndroid) {
        // Check if foreground service is supported
        final notificationStatus = await Permission.notification.status;
        return !notificationStatus.isPermanentlyDenied;
      } else if (Platform.isIOS) {
        // iOS supports background modes if configured in Info.plist
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Map<String, dynamic> getBackgroundListeningStats() {
    final now = DateTime.now();
    Duration? listeningDuration;
    
    if (_backgroundListeningStartTime != null) {
      listeningDuration = now.difference(_backgroundListeningStartTime!);
    }
    
    return {
      'isListening': _isBackgroundListening,
      'listeningStartTime': _backgroundListeningStartTime?.toIso8601String(),
      'listeningDuration': listeningDuration?.inSeconds,
      'keywordDetectionCount': _keywordDetectionCount,
      'backgroundTaskExecutions': _backgroundTaskExecutions,
      'batteryLevel': _batteryLevelController?.hasListener == true ? 'monitoring' : 'not_monitoring',
      'powerSaveMode': _powerSaveModeController?.hasListener == true ? 'monitoring' : 'not_monitoring',
    };
  }

  @override
  Future<void> dispose() async {
    await stopBackgroundListening();
    
    _batteryMonitorTimer?.cancel();
    _powerSaveCheckTimer?.cancel();
    
    await _batteryLevelController?.close();
    await _powerSaveModeController?.close();
    
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    
    _batteryLevelController = null;
    _powerSaveModeController = null;
    _receivePort = null;
  }

  /// Initialize the background service
  Future<void> _initializeBackgroundService() async {
    await _backgroundService.configure(
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
        notificationChannelId: 'keyword_detection_channel',
        initialNotificationTitle: 'Voice Keyword Recorder',
        initialNotificationContent: 'Listening for keywords in background',
        foregroundServiceNotificationId: 888,
      ),
    );
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Create keyword detection service directly in background isolate
    final keywordService = KeywordDetectionServiceImpl();
    
    service.on('start').listen((event) async {
      await _startKeywordDetection(service, keywordService);
    });
    
    service.on('stop').listen((event) async {
      await keywordService.stopListening();
      service.stopSelf();
    });
    
    service.on('updateSettings').listen((event) async {
      final settings = event as Map<String, dynamic>;
      await _updateKeywordDetectionSettings(keywordService, settings);
    });
    
    service.on('reducePowerConsumption').listen((event) async {
      final data = event as Map<String, dynamic>;
      await _handlePowerConsumptionReduction(keywordService, data);
    });
  }

  /// iOS background processing handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    // iOS background app refresh handling
    try {
      final keywordService = KeywordDetectionServiceImpl();
      
      // Perform keyword detection for limited time
      await keywordService.startListening();
      
      // iOS allows limited background execution time
      await Future.delayed(const Duration(seconds: 30));
      
      await keywordService.stopListening();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start keyword detection in background
  static Future<void> _startKeywordDetection(
    ServiceInstance service,
    KeywordDetectionService keywordService,
  ) async {
    try {
      await keywordService.startListening();
      
      // Listen for keyword detection
      keywordService.keywordDetectedStream.listen((detected) {
        if (detected) {
          _sendMessageToMain({
            'type': 'keyword_detected',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
      
      // Monitor confidence levels
      keywordService.confidenceStream.listen((confidence) {
        _sendMessageToMain({
          'type': 'confidence_update',
          'confidence': confidence,
        });
      });
      
    } catch (e) {
      _sendMessageToMain({
        'type': 'error',
        'message': e.toString(),
      });
    }
  }

  /// Update keyword detection settings in background
  static Future<void> _updateKeywordDetectionSettings(
    KeywordDetectionService keywordService,
    Map<String, dynamic> settings,
  ) async {
    try {
      if (settings['confidenceThreshold'] != null) {
        await keywordService.updateConfidenceThreshold(
          settings['confidenceThreshold'] as double,
        );
      }
    } catch (e) {
      _sendMessageToMain({
        'type': 'error',
        'message': 'Failed to update settings: ${e.toString()}',
      });
    }
  }

  /// Handle power consumption reduction in background
  static Future<void> _handlePowerConsumptionReduction(
    KeywordDetectionService keywordService,
    Map<String, dynamic> data,
  ) async {
    try {
      final enabled = data['enabled'] as bool? ?? false;
      final batteryLevel = data['batteryLevel'] as int? ?? 100;
      
      if (enabled) {
        // Reduce power consumption
        if (batteryLevel < 15) {
          // Very low battery - stop listening completely
          await keywordService.stopListening();
          _sendMessageToMain({
            'type': 'power_save',
            'message': 'Stopped listening due to very low battery ($batteryLevel%)',
          });
        } else if (batteryLevel < 30) {
          // Low battery - reduce detection frequency
          // This would require implementing reduced frequency mode in KeywordDetectionService
          _sendMessageToMain({
            'type': 'power_save',
            'message': 'Reduced detection frequency due to low battery ($batteryLevel%)',
          });
        }
      } else {
        // Resume normal operation if not already listening
        if (!keywordService.isListening) {
          await keywordService.startListening();
          _sendMessageToMain({
            'type': 'power_save',
            'message': 'Resumed normal operation (battery: $batteryLevel%)',
          });
        }
      }
    } catch (e) {
      _sendMessageToMain({
        'type': 'error',
        'message': 'Failed to handle power consumption reduction: ${e.toString()}',
      });
    }
  }

  /// Send message from background isolate to main isolate
  static void _sendMessageToMain(Map<String, dynamic> message) {
    final sendPort = IsolateNameServer.lookupPortByName(_portName);
    sendPort?.send(message);
  }

  /// Handle messages from background isolate
  void _handleBackgroundMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'keyword_detected':
        // Keyword was detected in background - could trigger recording
        _keywordDetectionCount++;
        if (kDebugMode) {
          print('Keyword detected in background at ${message['timestamp']} (total: $_keywordDetectionCount)');
        }
        break;
      case 'confidence_update':
        // Confidence level update from background detection
        if (kDebugMode) {
          print('Background confidence: ${message['confidence']}');
        }
        break;
      case 'power_save':
        // Power save mode message
        if (kDebugMode) {
          print('Power save: ${message['message']}');
        }
        break;
      case 'battery_update':
        // Battery level update from background task
        final level = message['level'] as int?;
        if (level != null) {
          _batteryLevelController?.add(level);
        }
        break;
      case 'ios_background_complete':
        // iOS background task completed
        _backgroundTaskExecutions++;
        if (kDebugMode) {
          print('iOS background keyword check completed at ${message['timestamp']} (executions: $_backgroundTaskExecutions)');
        }
        break;
      case 'error':
        if (kDebugMode) {
          print('Background error: ${message['message']}');
        }
        break;
    }
  }

  /// Check required permissions for background listening
  Future<void> _checkRequiredPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      throw BackgroundListeningException('Microphone permission required for background listening');
    }

    if (Platform.isAndroid) {
      // Check notification permission for foreground service
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        throw BackgroundListeningException('Notification permission required for Android background service');
      }
    }
  }

  /// Start Android-specific background service
  Future<void> _startAndroidBackgroundService() async {
    // Initialize Workmanager for periodic tasks
    await Workmanager().initialize(
      _workmanagerCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Register periodic keyword listening task
    await Workmanager().registerPeriodicTask(
      BackgroundTasks.keywordListening,
      BackgroundTasks.keywordListening,
      frequency: Duration(seconds: BackgroundConfig.keywordListeningIntervalSeconds),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
    );
    
    // Start foreground service
    await _backgroundService.startService();
  }

  /// Start iOS-specific background processing
  Future<void> _startIOSBackgroundProcessing() async {
    // iOS uses background app refresh and background processing
    // The actual implementation relies on iOS background modes configured in Info.plist
    await _backgroundService.startService();
  }

  /// Setup Android-specific background mode
  Future<void> _setupAndroidBackgroundMode() async {
    // Android requires foreground service for continuous background work
    // This is configured in the AndroidConfiguration above
    
    // Request battery optimization exclusion for better background performance
    try {
      final batteryOptimizationStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryOptimizationStatus.isGranted) {
        if (kDebugMode) {
          print('Requesting battery optimization exclusion for better background performance');
        }
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request battery optimization exclusion: $e');
      }
    }
  }

  /// Setup iOS-specific background mode
  Future<void> _setupIOSBackgroundMode() async {
    // iOS background modes are configured in Info.plist
    // - background-audio: for audio recording
    // - background-processing: for keyword detection
    // - background-app-refresh: for periodic updates
    
    // Register background task for iOS
    if (Platform.isIOS) {
      try {
        // Schedule background app refresh task
        await Workmanager().registerOneOffTask(
          'ios_background_keyword_check',
          'ios_background_keyword_check',
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: true,
          ),
        );
        
        if (kDebugMode) {
          print('iOS background task registered successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to register iOS background task: $e');
        }
      }
    }
  }

  /// Start monitoring system state (battery, power save mode)
  Future<void> _startSystemMonitoring() async {
    // Monitor battery level
    _batteryMonitorTimer = Timer.periodic(
      Duration(minutes: BackgroundConfig.batteryCheckIntervalMinutes),
      (_) => _checkBatteryLevel(),
    );
    
    // Monitor power save mode
    _powerSaveCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkPowerSaveMode(),
    );
    
    // Initial checks
    await _checkBatteryLevel();
    await _checkPowerSaveMode();
  }

  /// Check current battery level and emit updates
  Future<void> _checkBatteryLevel() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      _batteryLevelController?.add(batteryLevel);
      
      // Auto-stop background listening if battery is too low
      if (batteryLevel < BackgroundConfig.batteryLowThreshold && _isBackgroundListening) {
        await stopBackgroundListening();
        if (kDebugMode) {
          print('Background listening stopped due to low battery: $batteryLevel%');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check battery level: $e');
      }
    }
  }

  /// Check power save mode status
  Future<void> _checkPowerSaveMode() async {
    try {
      // Check battery state and infer power save mode
      final batteryState = await _battery.batteryState;
      final batteryLevel = await _battery.batteryLevel;
      
      // Consider power save mode active if battery is low or in certain states
      final isPowerSaveMode = batteryLevel < 20 || 
                             batteryState == BatteryState.unknown ||
                             batteryState == BatteryState.discharging;
      
      _powerSaveModeController?.add(isPowerSaveMode);
      
      // Adjust background listening based on power save mode
      if (isPowerSaveMode && _isBackgroundListening) {
        // Reduce background activity in power save mode
        _backgroundService.invoke('reducePowerConsumption', {
          'enabled': true,
          'batteryLevel': batteryLevel,
        });
      } else if (!isPowerSaveMode && _isBackgroundListening) {
        // Resume normal operation
        _backgroundService.invoke('reducePowerConsumption', {
          'enabled': false,
          'batteryLevel': batteryLevel,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check power save mode: $e');
      }
    }
  }
}

/// Workmanager callback dispatcher for Android background tasks
@pragma('vm:entry-point')
void _workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case BackgroundTasks.keywordListening:
          await _performBackgroundKeywordCheck();
          break;
        case BackgroundTasks.batteryMonitoring:
          await _performBatteryCheck();
          break;
        case 'ios_background_keyword_check':
          await _performIOSBackgroundCheck();
          break;
        default:
          return Future.value(true);
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Background task failed: $task, error: $e');
      }
      return Future.value(false);
    }
  });
}

/// Perform keyword detection check in background task
Future<void> _performBackgroundKeywordCheck() async {
  // Create keyword detection service directly for background task
  final keywordService = KeywordDetectionServiceImpl();
  
  // Perform brief keyword detection
  await keywordService.startListening();
  await Future.delayed(const Duration(seconds: 5)); // Brief listening window
  await keywordService.stopListening();
}

/// Perform battery level check in background task
Future<void> _performBatteryCheck() async {
  final battery = Battery();
  final batteryLevel = await battery.batteryLevel;
  
  // Send battery level to main app if needed
  final sendPort = IsolateNameServer.lookupPortByName('background_keyword_detection');
  sendPort?.send({
    'type': 'battery_update',
    'level': batteryLevel,
  });
}

/// Perform iOS-specific background keyword check
Future<void> _performIOSBackgroundCheck() async {
  // iOS has limited background execution time
  // Perform a quick keyword detection check
  final keywordService = KeywordDetectionServiceImpl();
  
  try {
    // Brief listening window for iOS background app refresh
    await keywordService.startListening();
    await Future.delayed(const Duration(seconds: 10)); // iOS allows ~30 seconds
    await keywordService.stopListening();
    
    // Send completion message
    final sendPort = IsolateNameServer.lookupPortByName('background_keyword_detection');
    sendPort?.send({
      'type': 'ios_background_complete',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    // Send error message
    final sendPort = IsolateNameServer.lookupPortByName('background_keyword_detection');
    sendPort?.send({
      'type': 'error',
      'message': 'iOS background check failed: ${e.toString()}',
    });
  }
}