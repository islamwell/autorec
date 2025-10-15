import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/service_locator.dart';
import '../../providers/permission_provider.dart';

/// Screen that handles permission requests with explanatory content
class PermissionRequestScreen extends ConsumerStatefulWidget {
  final List<AppPermission> requiredPermissions;
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionRequestScreen({
    super.key,
    required this.requiredPermissions,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  ConsumerState<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends ConsumerState<PermissionRequestScreen> {
  bool _isRequesting = false;
  Map<AppPermission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final statuses = <AppPermission, PermissionStatus>{};
    
    for (final permission in widget.requiredPermissions) {
      try {
        statuses[permission] = await permissionService.checkPermission(permission);
      } catch (e) {
        statuses[permission] = PermissionStatus.denied;
      }
    }
    
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    
    setState(() {
      _isRequesting = true;
    });

    try {
      final permissionService = ref.read(permissionServiceProvider);
      final results = await permissionService.requestMultiplePermissions(
        widget.requiredPermissions,
      );
      
      setState(() {
        _permissionStatuses = results;
        _isRequesting = false;
      });
      
      // Check if all permissions are granted
      final allGranted = results.values.every(
        (status) => status == PermissionStatus.granted,
      );
      
      if (allGranted) {
        widget.onPermissionsGranted?.call();
      } else {
        widget.onPermissionsDenied?.call();
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openAppSettings() async {
    try {
      final permissionService = ref.read(permissionServiceProvider);
      await permissionService.openAppSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open app settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(theme),
                const SizedBox(height: 40),
                Expanded(
                  child: _buildPermissionsList(theme),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.security,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions Required',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Voice Keyword Recorder needs these permissions to function properly',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPermissionsList(ThemeData theme) {
    return ListView.builder(
      itemCount: widget.requiredPermissions.length,
      itemBuilder: (context, index) {
        final permission = widget.requiredPermissions[index];
        final status = _permissionStatuses[permission] ?? PermissionStatus.denied;
        
        return _buildPermissionCard(permission, status, theme);
      },
    );
  }

  Widget _buildPermissionCard(
    AppPermission permission,
    PermissionStatus status,
    ThemeData theme,
  ) {
    final permissionService = ref.read(permissionServiceProvider);
    final rationale = permissionService.getPermissionRationale(permission);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getPermissionColor(permission, theme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPermissionIcon(permission),
                      color: _getPermissionColor(permission, theme),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPermissionTitle(permission),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(status, theme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                rationale,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PermissionStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case PermissionStatus.granted:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = 'Granted';
        icon = Icons.check_circle;
        break;
      case PermissionStatus.denied:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Not Granted';
        icon = Icons.warning;
        break;
      case PermissionStatus.permanentlyDenied:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = 'Permanently Denied';
        icon = Icons.block;
        break;
      case PermissionStatus.restricted:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = 'Restricted';
        icon = Icons.lock;
        break;
      case PermissionStatus.limited:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Limited';
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final hasPermissionsDenied = _permissionStatuses.values.any(
      (status) => status != PermissionStatus.granted,
    );
    
    final hasPermanentlyDenied = _permissionStatuses.values.any(
      (status) => status == PermissionStatus.permanentlyDenied,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPermissionsDenied) ...[
          ElevatedButton(
            onPressed: _isRequesting ? null : _requestPermissions,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return theme.colorScheme.onSurface.withOpacity(0.12);
                }
                return null;
              }),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isRequesting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Grant Permissions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (hasPermanentlyDenied) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openAppSettings,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Text(
                'Open App Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ] else ...[
          ElevatedButton(
            onPressed: widget.onPermissionsGranted,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Continue',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getPermissionTitle(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return 'Microphone Access';
      case AppPermission.storage:
        return 'Storage Access';
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

  Color _getPermissionColor(AppPermission permission, ThemeData theme) {
    switch (permission) {
      case AppPermission.microphone:
        return theme.colorScheme.primary;
      case AppPermission.storage:
        return theme.colorScheme.secondary;
      case AppPermission.notification:
        return theme.colorScheme.tertiary;
      case AppPermission.backgroundAudio:
        return Colors.purple;
    }
  }
}