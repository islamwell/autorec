/// Enum representing different permission types
enum AppPermission {
  microphone,
  storage,
  notification,
  backgroundAudio,
}

/// Enum representing permission status
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

/// Abstract interface for managing app permissions
abstract class PermissionService {
  /// Checks the current status of a specific permission
  /// [permission] the permission to check
  /// Returns the current [PermissionStatus]
  Future<PermissionStatus> checkPermission(AppPermission permission);

  /// Requests a specific permission from the user
  /// [permission] the permission to request
  /// Returns the resulting [PermissionStatus] after user interaction
  Future<PermissionStatus> requestPermission(AppPermission permission);

  /// Requests multiple permissions at once
  /// [permissions] list of permissions to request
  /// Returns a map of permissions to their resulting status
  Future<Map<AppPermission, PermissionStatus>> requestMultiplePermissions(
    List<AppPermission> permissions,
  );

  /// Checks if all required permissions are granted
  /// Returns true if all essential permissions are granted
  Future<bool> hasAllRequiredPermissions();

  /// Opens the app settings page for manual permission management
  /// Returns true if settings were opened successfully
  Future<bool> openAppSettings();

  /// Checks if a permission can be requested (not permanently denied)
  /// [permission] the permission to check
  /// Returns true if the permission can be requested
  Future<bool> canRequestPermission(AppPermission permission);

  /// Gets a user-friendly explanation for why a permission is needed
  /// [permission] the permission to explain
  /// Returns a localized explanation string
  String getPermissionRationale(AppPermission permission);

  /// Stream that emits permission status changes
  Stream<Map<AppPermission, PermissionStatus>> get permissionStatusStream;
}

/// Exception thrown when permission operations fail
class PermissionException implements Exception {
  final String message;
  final AppPermission? permission;
  final dynamic originalError;

  const PermissionException(this.message, [this.permission, this.originalError]);

  @override
  String toString() => 'PermissionException: $message';
}