import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permissions/permission_service.dart';
import '../services/service_locator.dart';

/// Provider for permission status management
final permissionStatusProvider = StateNotifierProvider<PermissionStatusNotifier, Map<AppPermission, PermissionStatus>>((ref) {
  return PermissionStatusNotifier(ref);
});

/// Provider for checking if all required permissions are granted
final hasAllRequiredPermissionsProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.hasAllRequiredPermissions();
});

/// Provider for permission service stream
final permissionStreamProvider = StreamProvider<Map<AppPermission, PermissionStatus>>((ref) {
  final permissionService = ref.read(permissionServiceProvider);
  return permissionService.permissionStatusStream;
});

/// State notifier for managing permission status
class PermissionStatusNotifier extends StateNotifier<Map<AppPermission, PermissionStatus>> {
  late final PermissionService _permissionService;
  late final Ref _ref;

  PermissionStatusNotifier(this._ref) : super({}) {
    _permissionService = _ref.read(permissionServiceProvider);
    _initializePermissions();
    _listenToPermissionChanges();
  }

  /// Initialize permission statuses
  Future<void> _initializePermissions() async {
    try {
      final statuses = <AppPermission, PermissionStatus>{};
      
      for (final permission in AppPermission.values) {
        statuses[permission] = await _permissionService.checkPermission(permission);
      }
      
      state = statuses;
    } catch (e) {
      // If initialization fails, set all permissions to denied
      state = Map.fromEntries(
        AppPermission.values.map(
          (permission) => MapEntry(permission, PermissionStatus.denied),
        ),
      );
    }
  }

  /// Listen to permission status changes
  void _listenToPermissionChanges() {
    _permissionService.permissionStatusStream.listen(
      (changes) {
        state = {...state, ...changes};
      },
      onError: (error) {
        // Handle stream errors gracefully
      },
    );
  }

  /// Request a specific permission
  Future<PermissionStatus> requestPermission(AppPermission permission) async {
    try {
      final status = await _permissionService.requestPermission(permission);
      state = {...state, permission: status};
      return status;
    } catch (e) {
      // If request fails, mark as denied
      state = {...state, permission: PermissionStatus.denied};
      return PermissionStatus.denied;
    }
  }

  /// Request multiple permissions
  Future<Map<AppPermission, PermissionStatus>> requestMultiplePermissions(
    List<AppPermission> permissions,
  ) async {
    try {
      final results = await _permissionService.requestMultiplePermissions(permissions);
      state = {...state, ...results};
      return results;
    } catch (e) {
      // If request fails, mark all as denied
      final deniedResults = Map.fromEntries(
        permissions.map((p) => MapEntry(p, PermissionStatus.denied)),
      );
      state = {...state, ...deniedResults};
      return deniedResults;
    }
  }

  /// Check if a permission can be requested
  Future<bool> canRequestPermission(AppPermission permission) async {
    try {
      return await _permissionService.canRequestPermission(permission);
    } catch (e) {
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await _permissionService.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Refresh all permission statuses
  Future<void> refreshPermissions() async {
    await _initializePermissions();
  }

  /// Get permission rationale
  String getPermissionRationale(AppPermission permission) {
    return _permissionService.getPermissionRationale(permission);
  }

  /// Check if all required permissions are granted
  bool get hasAllRequiredPermissions {
    final requiredPermissions = [
      AppPermission.microphone,
      AppPermission.storage,
    ];
    
    return requiredPermissions.every(
      (permission) => state[permission] == PermissionStatus.granted,
    );
  }

  /// Get the status of a specific permission
  PermissionStatus getPermissionStatus(AppPermission permission) {
    return state[permission] ?? PermissionStatus.denied;
  }

  /// Check if any permissions are permanently denied
  bool get hasPermanentlyDeniedPermissions {
    return state.values.any(
      (status) => status == PermissionStatus.permanentlyDenied,
    );
  }

  /// Get list of permissions that need to be requested
  List<AppPermission> get permissionsToRequest {
    return state.entries
        .where((entry) => entry.value != PermissionStatus.granted)
        .map((entry) => entry.key)
        .toList();
  }
}