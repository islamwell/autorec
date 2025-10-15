import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permissions/permission_service.dart';
import '../../providers/permission_provider.dart';

/// Screen displayed when critical permissions are denied
class PermissionDeniedScreen extends ConsumerWidget {
  final List<AppPermission> deniedPermissions;
  final VoidCallback? onRetry;
  final VoidCallback? onSkip;

  const PermissionDeniedScreen({
    super.key,
    required this.deniedPermissions,
    this.onRetry,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final permissionNotifier = ref.read(permissionStatusProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.error.withOpacity(0.1),
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
                const SizedBox(height: 60),
                _buildHeader(theme),
                const SizedBox(height: 40),
                Expanded(
                  child: _buildContent(theme, permissionNotifier),
                ),
                _buildActionButtons(theme, permissionNotifier),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.block,
            size: 50,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions Required',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Some permissions were denied. The app needs these permissions to function properly.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, PermissionStatusNotifier permissionNotifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Denied Permissions:',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...deniedPermissions.map((permission) => _buildPermissionItem(
            permission,
            theme,
            permissionNotifier,
          )),
          const SizedBox(height: 32),
          _buildInstructions(theme),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    AppPermission permission,
    ThemeData theme,
    PermissionStatusNotifier permissionNotifier,
  ) {
    final rationale = permissionNotifier.getPermissionRationale(permission);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPermissionIcon(permission),
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPermissionTitle(permission),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rationale,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildInstructions(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Grant Permissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              '1.',
              'Tap "Open App Settings" below',
              theme,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '2.',
              'Find "Permissions" in the app settings',
              theme,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '3.',
              'Enable the required permissions',
              theme,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '4.',
              'Return to the app and tap "Try Again"',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, PermissionStatusNotifier permissionNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () async {
            await permissionNotifier.openAppSettings();
          },
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
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Open App Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
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
            'Try Again',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Continue with Limited Features',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                decoration: TextDecoration.underline,
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
}