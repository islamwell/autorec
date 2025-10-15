import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../providers/recording_provider.dart';
import '../providers/background_listening_provider.dart';
import '../providers/settings_provider.dart';

/// Widget that displays the current app state for debugging and monitoring
class AppStateIndicator extends ConsumerWidget {
  final bool showDetails;
  
  const AppStateIndicator({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final recordingState = ref.watch(recordingProvider);
    final backgroundState = ref.watch(backgroundListeningProvider);
    final settingsState = ref.watch(settingsProvider);

    if (!showDetails) {
      return _buildCompactIndicator(context, appState, recordingState, backgroundState);
    }

    return _buildDetailedIndicator(context, appState, recordingState, backgroundState, settingsState);
  }

  Widget _buildCompactIndicator(
    BuildContext context,
    AppState appState,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(appState, recordingState, backgroundState).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(appState, recordingState, backgroundState),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(appState, recordingState, backgroundState),
            size: 16,
            color: _getStatusColor(appState, recordingState, backgroundState),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(appState, recordingState, backgroundState),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(appState, recordingState, backgroundState),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedIndicator(
    BuildContext context,
    AppState appState,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
    SettingsState settingsState,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'App State',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildStateRow(
              context,
              'Initialized',
              appState.isInitialized,
              appState.isInitialized ? Icons.check_circle : Icons.pending,
            ),
            
            _buildStateRow(
              context,
              'Permissions',
              appState.hasRequiredPermissions,
              appState.hasRequiredPermissions ? Icons.security : Icons.warning,
            ),
            
            _buildStateRow(
              context,
              'Recording',
              recordingState.isRecording,
              recordingState.isRecording ? Icons.fiber_manual_record : Icons.stop_circle,
            ),
            
            _buildStateRow(
              context,
              'Keyword Listening',
              backgroundState.isListening,
              backgroundState.isListening ? Icons.hearing : Icons.hearing_disabled,
            ),
            
            _buildStateRow(
              context,
              'Settings Loaded',
              !settingsState.isLoading,
              !settingsState.isLoading ? Icons.settings : Icons.hourglass_empty,
            ),
            
            if (appState.recordings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Recordings: ${appState.recordings.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            
            if (appState.lastError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appState.lastError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(
    BuildContext context,
    String label,
    bool isActive,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(
    AppState appState,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
  ) {
    if (appState.lastError != null) {
      return Colors.red.shade600;
    } else if (recordingState.isRecording) {
      return Colors.red.shade500;
    } else if (backgroundState.isListening) {
      return Colors.green.shade600;
    } else if (appState.isInitialized && appState.hasRequiredPermissions) {
      return Colors.blue.shade600;
    } else {
      return Colors.orange.shade600;
    }
  }

  IconData _getStatusIcon(
    AppState appState,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
  ) {
    if (appState.lastError != null) {
      return Icons.error;
    } else if (recordingState.isRecording) {
      return Icons.fiber_manual_record;
    } else if (backgroundState.isListening) {
      return Icons.hearing;
    } else if (appState.isInitialized && appState.hasRequiredPermissions) {
      return Icons.check_circle;
    } else {
      return Icons.warning;
    }
  }

  String _getStatusText(
    AppState appState,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
  ) {
    if (appState.lastError != null) {
      return 'Error';
    } else if (recordingState.isRecording) {
      return 'Recording';
    } else if (backgroundState.isListening) {
      return 'Listening';
    } else if (appState.isInitialized && appState.hasRequiredPermissions) {
      return 'Ready';
    } else {
      return 'Setup Required';
    }
  }
}