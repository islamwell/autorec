import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permissions/permission_service.dart';
import '../../providers/permission_provider.dart';

/// Demo screen to test permission functionality
class PermissionDemoScreen extends ConsumerWidget {
  const PermissionDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatuses = ref.watch(permissionStatusProvider);
    final permissionNotifier = ref.read(permissionStatusProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Demo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Status',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...AppPermission.values.map((permission) {
                        final status = permissionStatuses[permission] ?? PermissionStatus.denied;
                        return _buildPermissionRow(permission, status, theme);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Actions',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await permissionNotifier.refreshPermissions();
                        },
                        child: const Text('Refresh Permissions'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await permissionNotifier.requestPermission(AppPermission.microphone);
                        },
                        child: const Text('Request Microphone'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await permissionNotifier.requestPermission(AppPermission.storage);
                        },
                        child: const Text('Request Storage'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await permissionNotifier.requestMultiplePermissions([
                            AppPermission.microphone,
                            AppPermission.storage,
                          ]);
                        },
                        child: const Text('Request All Required'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          await permissionNotifier.openAppSettings();
                        },
                        child: const Text('Open App Settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: permissionNotifier.hasAllRequiredPermissions
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: permissionNotifier.hasAllRequiredPermissions
                        ? Colors.green
                        : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      permissionNotifier.hasAllRequiredPermissions
                          ? Icons.check_circle
                          : Icons.warning,
                      color: permissionNotifier.hasAllRequiredPermissions
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        permissionNotifier.hasAllRequiredPermissions
                            ? 'All required permissions granted!'
                            : 'Some permissions are missing',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: permissionNotifier.hasAllRequiredPermissions
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(AppPermission permission, PermissionStatus status, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case PermissionStatus.granted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PermissionStatus.denied:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case PermissionStatus.permanentlyDenied:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case PermissionStatus.restricted:
        statusColor = Colors.grey;
        statusIcon = Icons.lock;
        break;
      case PermissionStatus.limited:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _getPermissionIcon(permission),
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getPermissionName(permission),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            status.name,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return 'Microphone';
      case AppPermission.storage:
        return 'Storage';
      case AppPermission.notification:
        return 'Notifications';
      case AppPermission.backgroundAudio:
        return 'Background Audio';
    }
  }

  IconData _getPermissionIcon(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return Icons.mic;
      case AppPermission.storage:
        return Icons.storage;
      case AppPermission.notification:
        return Icons.notifications;
      case AppPermission.backgroundAudio:
        return Icons.headset;
    }
  }
}