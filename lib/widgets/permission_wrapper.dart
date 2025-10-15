import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permissions/permission_service.dart';
import '../providers/permission_provider.dart';
import '../screens/permissions/permission_request_screen.dart';
import '../screens/permissions/permission_denied_screen.dart';

/// Widget that wraps content and handles permission checking/requesting
class PermissionWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final List<AppPermission> requiredPermissions;
  final bool showPermissionScreens;
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionWrapper({
    super.key,
    required this.child,
    this.requiredPermissions = const [
      AppPermission.microphone,
      AppPermission.storage,
    ],
    this.showPermissionScreens = true,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  ConsumerState<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends ConsumerState<PermissionWrapper> {
  bool _isCheckingPermissions = true;
  bool _hasRequiredPermissions = false;
  bool _showPermissionRequest = false;
  bool _showPermissionDenied = false;
  List<AppPermission> _deniedPermissions = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final permissionNotifier = ref.read(permissionStatusProvider.notifier);
      await permissionNotifier.refreshPermissions();
      
      final permissionStatuses = ref.read(permissionStatusProvider);
      final deniedPermissions = <AppPermission>[];
      bool allGranted = true;

      for (final permission in widget.requiredPermissions) {
        final status = permissionStatuses[permission] ?? PermissionStatus.denied;
        if (status != PermissionStatus.granted) {
          allGranted = false;
          deniedPermissions.add(permission);
        }
      }

      if (mounted) {
        setState(() {
          _hasRequiredPermissions = allGranted;
          _deniedPermissions = deniedPermissions;
          _isCheckingPermissions = false;
          
          if (!allGranted && widget.showPermissionScreens) {
            _showPermissionRequest = true;
          }
        });

        if (allGranted) {
          widget.onPermissionsGranted?.call();
        } else {
          widget.onPermissionsDenied?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasRequiredPermissions = false;
          _isCheckingPermissions = false;
          _deniedPermissions = widget.requiredPermissions;
          
          if (widget.showPermissionScreens) {
            _showPermissionRequest = true;
          }
        });
        
        widget.onPermissionsDenied?.call();
      }
    }
  }

  void _onPermissionsGranted() {
    setState(() {
      _hasRequiredPermissions = true;
      _showPermissionRequest = false;
      _showPermissionDenied = false;
    });
    widget.onPermissionsGranted?.call();
  }

  void _onPermissionsDenied() {
    setState(() {
      _showPermissionRequest = false;
      _showPermissionDenied = true;
    });
    widget.onPermissionsDenied?.call();
  }

  void _onRetryPermissions() {
    setState(() {
      _showPermissionDenied = false;
      _showPermissionRequest = true;
    });
  }

  void _onSkipPermissions() {
    setState(() {
      _showPermissionRequest = false;
      _showPermissionDenied = false;
    });
    // Allow user to continue with limited functionality
  }

  @override
  Widget build(BuildContext context) {
    // Listen to permission status changes
    ref.listen<Map<AppPermission, PermissionStatus>>(
      permissionStatusProvider,
      (previous, next) {
        if (previous != next) {
          _checkPermissions();
        }
      },
    );

    if (_isCheckingPermissions) {
      return _buildLoadingScreen();
    }

    if (!widget.showPermissionScreens) {
      return widget.child;
    }

    if (_showPermissionRequest) {
      return PermissionRequestScreen(
        requiredPermissions: _deniedPermissions,
        onPermissionsGranted: _onPermissionsGranted,
        onPermissionsDenied: _onPermissionsDenied,
      );
    }

    if (_showPermissionDenied) {
      return PermissionDeniedScreen(
        deniedPermissions: _deniedPermissions,
        onRetry: _onRetryPermissions,
        onSkip: _onSkipPermissions,
      );
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Checking Permissions...',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we verify app permissions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget for wrapping the entire app with permission checking
class AppPermissionWrapper extends ConsumerWidget {
  final Widget child;

  const AppPermissionWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionWrapper(
      requiredPermissions: const [
        AppPermission.microphone,
        AppPermission.storage,
      ],
      child: child,
    );
  }
}

/// Widget for checking specific permissions without showing full screens
class PermissionChecker extends ConsumerWidget {
  final List<AppPermission> permissions;
  final Widget Function(BuildContext context, bool hasPermissions) builder;

  const PermissionChecker({
    super.key,
    required this.permissions,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatuses = ref.watch(permissionStatusProvider);
    
    final hasAllPermissions = permissions.every(
      (permission) => permissionStatuses[permission] == PermissionStatus.granted,
    );

    return builder(context, hasAllPermissions);
  }
}