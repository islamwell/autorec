import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permissions/permission_service.dart';
import '../services/service_locator.dart';

/// Simple provider that checks if microphone permission is granted
final hasMicrophonePermissionProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.read(permissionServiceProvider);
  final status = await permissionService.checkPermission(AppPermission.microphone);
  return status == PermissionStatus.granted;
});

/// Provider to request microphone permission
final requestMicrophonePermissionProvider = Provider((ref) {
  return () async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestPermission(AppPermission.microphone);
    // Invalidate the permission check to refresh UI
    ref.invalidate(hasMicrophonePermissionProvider);
    return status == PermissionStatus.granted;
  };
});
