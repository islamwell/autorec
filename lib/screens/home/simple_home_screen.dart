import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/simple_keyword_recorder_provider.dart';

/// Simple home screen with Material Design 3
/// Shows two main buttons: Record Keyword and Pause/Resume Listening
class SimpleHomeScreen extends ConsumerWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorderState = ref.watch(simpleKeywordRecorderProvider);
    final recorderNotifier = ref.read(simpleKeywordRecorderProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Title
              Text(
                'Voice Keyword Recorder',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Record a keyword, then auto-record when it\'s detected',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 64),

              // Status Card with dark round shadow
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 4),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getStatusColor(recorderState, theme),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(recorderState, theme).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStatusIcon(recorderState),
                        size: 40,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Text
                    Text(
                      _getStatusText(recorderState),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Detail Text
                    Text(
                      _getDetailText(recorderState),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Keyword Button with dark round shadow
              _buildActionButton(
                context: context,
                theme: theme,
                label: recorderState.isRecordingKeyword ? 'Recording Keyword...' : 'Record Keyword',
                icon: recorderState.isRecordingKeyword ? Icons.stop_circle : Icons.mic,
                color: theme.colorScheme.primary,
                onPressed: recorderState.isRecordingKeyword
                    ? () => recorderNotifier.stopKeywordRecording()
                    : () => recorderNotifier.startKeywordRecording(),
                enabled: !recorderState.isAutoRecording,
              ),

              const SizedBox(height: 16),

              // Pause/Resume Button with dark round shadow
              _buildActionButton(
                context: context,
                theme: theme,
                label: recorderState.isListening ? 'Pause Listening' : 'Start Listening',
                icon: recorderState.isListening ? Icons.pause_circle : Icons.play_circle,
                color: recorderState.isListening
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
                onPressed: recorderState.isListening
                    ? () => recorderNotifier.pauseListening()
                    : () => recorderNotifier.startListening(),
                enabled: recorderState.hasKeyword && !recorderState.isRecordingKeyword,
              ),

              const SizedBox(height: 32),

              // Error Message
              if (recorderState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recorderState.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Recordings Count
              if (recorderState.recordingsCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '${recorderState.recordingsCount} recording${recorderState.recordingsCount == 1 ? '' : 's'} saved',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                  spreadRadius: -8,
                ),
              ]
            : [],
      ),
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SimpleKeywordRecorderState state, ThemeData theme) {
    if (state.isAutoRecording) return theme.colorScheme.error;
    if (state.isRecordingKeyword) return theme.colorScheme.primary;
    if (state.isListening) return theme.colorScheme.tertiary;
    return theme.colorScheme.surfaceContainerHighest;
  }

  IconData _getStatusIcon(SimpleKeywordRecorderState state) {
    if (state.isAutoRecording) return Icons.fiber_manual_record;
    if (state.isRecordingKeyword) return Icons.mic;
    if (state.isListening) return Icons.hearing;
    return Icons.mic_off;
  }

  String _getStatusText(SimpleKeywordRecorderState state) {
    if (state.isAutoRecording) return 'Recording (10 min)';
    if (state.isRecordingKeyword) return 'Recording Keyword';
    if (state.isListening) return 'Listening for Keyword';
    if (state.hasKeyword) return 'Ready';
    return 'No Keyword Set';
  }

  String _getDetailText(SimpleKeywordRecorderState state) {
    if (state.isAutoRecording) {
      final remaining = state.recordingTimeRemaining;
      if (remaining != null) {
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        return 'Time remaining: $minutes:${seconds.toString().padLeft(2, '0')}';
      }
      return 'Recording in progress...';
    }
    if (state.isRecordingKeyword) return 'Speak your keyword clearly';
    if (state.isListening) return 'Say your keyword to start recording';
    if (state.hasKeyword) return 'Press "Start Listening" to begin';
    return 'Press "Record Keyword" to get started';
  }
}
