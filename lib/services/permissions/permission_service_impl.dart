import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'permission_service.dart';

/// Concrete implementation of PermissionService using permission_handler plugin
class PermissionServiceImpl implements PermissionService {
  final StreamController<Map<AppPermission, PermissionStatus>> _statusController =
      StreamController<Map<AppPermission, PermissionStatus>>.broadcast();

  /// Maps app permissions to permission_handler permissions
  ph.Permission _mapToPluginPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return ph.Permission.microphone;
      case AppPermission.storage:
        // Use appropriate storage permission based on platform
        if (Platform.isAndroid) {
          return ph.Permission.storage;
        } else {
          return ph.Permission.photos; // iOS uses photos for storage access
        }
      case AppPermission.notification:
        return ph.Permission.notification;
      case AppPermission.backgroundAudio:
        // Background audio is handled differently on each platform
        if (Platform.isAndroid) {
          return ph.Permission.systemAlertWindow;
        } else {
          return ph.Permission.microphone; // iOS handles this through audio session
        }
    }
  }

  /// Maps permission_handler status to app permission status
  PermissionStatus _mapFromPluginStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return PermissionStatus.limited;
      case ph.PermissionStatus.provisional:
        return PermissionStatus.limited;
    }
  }

  @override
  Future<PermissionStatus> checkPermission(AppPermission permission) async {
    try {
      final pluginPermission = _mapToPluginPermission(permission);
      final status = await pluginPermission.status;
      final appStatus = _mapFromPluginStatus(status);
      
      // Emit status change
      _emitStatusChange({permission: appStatus});
      
      return appStatus;
    } catch (e) {
      throw PermissionException(
        'Failed to check permission: ${permission.name}',
        permission,
        e,
      );
    }
  }

  @override
  Future<PermissionStatus> requestPermission(AppPermission permission) async {
    try {
      // Check current status first
      final currentStatus = await checkPermission(permission);
      
      // If already granted, return immediately
      if (currentStatus == PermissionStatus.granted) {
        return currentStatus;
      }
      
      // If permanently denied, can't request again
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return currentStatus;
      }
      
      final pluginPermission = _mapToPluginPermission(permission);
      final status = await pluginPermission.request();
      final appStatus = _mapFromPluginStatus(status);
      
      // Emit status change
      _emitStatusChange({permission: appStatus});
      
      return appStatus;
    } catch (e) {
      throw PermissionException(
        'Failed to request permission: ${permission.name}',
        permission,
        e,
      );
    }
  }

  @override
  Future<Map<AppPermission, PermissionStatus>> requestMultiplePermissions(
    List<AppPermission> permissions,
  ) async {
    try {
      final pluginPermissions = permissions
          .map((p) => _mapToPluginPermission(p))
          .toList();
      
      final statuses = await pluginPermissions.request();
      final result = <AppPermission, PermissionStatus>{};
      
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        final pluginPermission = pluginPermissions[i];
        final status = statuses[pluginPermission];
        
        if (status != null) {
          result[permission] = _mapFromPluginStatus(status);
        } else {
          result[permission] = PermissionStatus.denied;
        }
      }
      
      // Emit status changes
      _emitStatusChange(result);
      
      return result;
    } catch (e) {
      throw PermissionException(
        'Failed to request multiple permissions',
        null,
        e,
      );
    }
  }

  @override
  Future<bool> hasAllRequiredPermissions() async {
    try {
      // Check essential permissions for the app
      final requiredPermissions = [
        AppPermission.microphone,
        AppPermission.storage,
      ];
      
      for (final permission in requiredPermissions) {
        final status = await checkPermission(permission);
        if (status != PermissionStatus.granted) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      throw PermissionException(
        'Failed to check required permissions',
        null,
        e,
      );
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      throw PermissionException(
        'Failed to open app settings',
        null,
        e,
      );
    }
  }

  @override
  Future<bool> canRequestPermission(AppPermission permission) async {
    try {
      final status = await checkPermission(permission);
      return status != PermissionStatus.permanentlyDenied &&
             status != PermissionStatus.restricted;
    } catch (e) {
      throw PermissionException(
        'Failed to check if permission can be requested: ${permission.name}',
        permission,
        e,
      );
    }
  }

  @override
  String getPermissionRationale(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return 'Microphone access is required to record audio and detect your custom keyword. '
               'This enables hands-free recording when you speak your keyword.';
      case AppPermission.storage:
        return 'Storage access is needed to save your recordings and export them as MP3 files. '
               'Your recordings are stored locally on your device.';
      case AppPermission.notification:
        return 'Notification permission allows the app to notify you when recordings start, '
               'stop, or when the auto-stop timer expires.';
      case AppPermission.backgroundAudio:
        return 'Background audio permission enables continuous keyword detection even when '
               'the app is not in the foreground, allowing hands-free operation.';
    }
  }

  @override
  Stream<Map<AppPermission, PermissionStatus>> get permissionStatusStream =>
      _statusController.stream;

  /// Emits permission status changes to the stream
  void _emitStatusChange(Map<AppPermission, PermissionStatus> changes) {
    if (!_statusController.isClosed) {
      _statusController.add(changes);
    }
  }

  /// Disposes resources
  void dispose() {
    _statusController.close();
  }

  /// Performs a comprehensive permission check with retry mechanism
  Future<Map<AppPermission, PermissionStatus>> checkAllPermissions() async {
    final permissions = AppPermission.values;
    final result = <AppPermission, PermissionStatus>{};
    
    for (final permission in permissions) {
      try {
        result[permission] = await checkPermission(permission);
      } catch (e) {
        // If individual permission check fails, mark as denied
        result[permission] = PermissionStatus.denied;
      }
    }
    
    return result;
  }

  /// Requests permissions with retry mechanism for better UX
  Future<PermissionStatus> requestPermissionWithRetry(
    AppPermission permission, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        final status = await requestPermission(permission);
        
        // If granted or permanently denied, return immediately
        if (status == PermissionStatus.granted ||
            status == PermissionStatus.permanentlyDenied) {
          return status;
        }
        
        attempts++;
        
        // Wait a bit before retry
        if (attempts < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
      }
    }
    
    // If all retries failed, return denied
    return PermissionStatus.denied;
  }

  /// Platform-specific permission handling for Android
  Future<bool> _handleAndroidPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // For Android 13+ (API 33), we need to handle storage permissions differently
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // Android 13+ uses scoped storage, no storage permission needed for app files
        return true;
      } else {
        // For older Android versions, request storage permission
        final status = await requestPermission(AppPermission.storage);
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      return false;
    }
  }

  /// Platform-specific permission handling for iOS
  Future<bool> _handleIOSPermissions() async {
    if (!Platform.isIOS) return true;
    
    try {
      // iOS handles storage through document picker, no explicit permission needed
      // Focus on microphone permission
      final micStatus = await requestPermission(AppPermission.microphone);
      return micStatus == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Gets Android API level (mock implementation for now)
  Future<int> _getAndroidVersion() async {
    // This would typically use device_info_plus plugin
    // For now, assume modern Android
    return 33;
  }

  /// Initializes platform-specific permission handling
  Future<void> initializePlatformPermissions() async {
    try {
      if (Platform.isAndroid) {
        await _handleAndroidPermissions();
      } else if (Platform.isIOS) {
        await _handleIOSPermissions();
      }
    } catch (e) {
      throw PermissionException(
        'Failed to initialize platform permissions',
        null,
        e,
      );
    }
  }
}