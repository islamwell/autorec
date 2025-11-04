import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recording_provider.dart';
import '../../providers/keyword_triggered_recording_provider.dart';
import '../../providers/keyword_training_provider.dart';
import '../../providers/background_listening_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/audio_level_indicator.dart';
import '../recordings/recordings_list_screen.dart';
import '../settings/settings_screen.dart';
import '../keyword_training/keyword_training_screen.dart';

/// Improved home screen with keyword-triggered recording and Material Design 3
class ImprovedHomeScreen extends ConsumerStatefulWidget {
  const ImprovedHomeScreen({super.key});

  @override
  ConsumerState<ImprovedHomeScreen> createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends ConsumerState<ImprovedHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final keywordState = ref.watch(keywordTriggeredRecordingProvider);
    final trainingState = ref.watch(keywordTrainingProvider);
    final backgroundState = ref.watch(backgroundListeningProvider);

    // Control pulse animation
    if (recordingState.isRecording || keywordState.isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Status cards
                      _buildStatusCard(context, recordingState, keywordState, trainingState),
                      const SizedBox(height: 20),

                      // Audio level indicator
                      if (recordingState.isRecording)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: AudioLevelIndicator(
                            audioLevel: recordingState.audioLevel,
                            qualityResult: recordingState.audioQuality,
                            isRecording: recordingState.isRecording,
                          ),
                        ),

                      // Keyword listening controls
                      _buildKeywordControls(context, keywordState, trainingState),
                      const SizedBox(height: 24),

                      // Manual recording controls
                      _buildRecordingControls(context, recordingState, keywordState),
                      const SizedBox(height: 24),

                      // Quick actions
                      _buildQuickActions(context),

                      // Battery info
                      if (backgroundState.batteryLevel < 30)
                        _buildBatteryWarning(context, backgroundState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mic_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Recorder',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                Text(
                  'Keyword-triggered recording',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    RecordingState recordingState,
    KeywordTriggeredRecordingState keywordState,
    KeywordTrainingState trainingState,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status items
            _buildStatusItem(
              context,
              icon: keywordState.isListening ? Icons.hearing : Icons.hearing_disabled,
              label: 'Keyword Listening',
              value: keywordState.isListening ? 'Active' : 'Inactive',
              isActive: keywordState.isListening,
            ),
            const SizedBox(height: 12),

            _buildStatusItem(
              context,
              icon: recordingState.isRecording ? Icons.fiber_manual_record : Icons.stop_circle_outlined,
              label: 'Recording',
              value: recordingState.isRecording
                  ? (keywordState.isAutoRecording ? 'Auto (Keyword)' : 'Manual')
                  : 'Stopped',
              isActive: recordingState.isRecording,
            ),
            const SizedBox(height: 12),

            if (recordingState.isRecording)
              _buildStatusItem(
                context,
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: _formatDuration(recordingState.recordingDuration),
                isActive: true,
              ),

            if (trainingState.trainedProfile != null) ...[
              const SizedBox(height: 12),
              _buildStatusItem(
                context,
                icon: Icons.check_circle_outline,
                label: 'Trained Keyword',
                value: trainingState.trainedProfile!.keyword,
                isActive: true,
              ),
            ],

            if (keywordState.isListening && keywordState.confidenceLevel > 0.5) ...[
              const SizedBox(height: 12),
              _buildStatusItem(
                context,
                icon: Icons.trending_up,
                label: 'Confidence',
                value: '${(keywordState.confidenceLevel * 100).toStringAsFixed(0)}%',
                isActive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordControls(
    BuildContext context,
    KeywordTriggeredRecordingState keywordState,
    KeywordTrainingState trainingState,
  ) {
    final hasTrainedKeyword = trainingState.trainedProfile != null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Keyword Detection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasTrainedKeyword) ...[
              Text(
                'Train a keyword to enable automatic recording when the keyword is detected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeywordTrainingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.school_outlined),
                label: const Text('Train Keyword'),
              ),
            ] else ...[
              Text(
                keywordState.isListening
                    ? 'Listening for "${trainingState.trainedProfile!.keyword}"...'
                    : 'Start listening to automatically record when keyword is detected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: keywordState.isListening
                        ? FilledButton.tonalIcon(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(keywordTriggeredRecordingProvider.notifier)
                                    .stopListening();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Listening'),
                          )
                        : FilledButton.icon(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(keywordTriggeredRecordingProvider.notifier)
                                    .startListening();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Now listening for keyword...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.hearing),
                            label: const Text('Start Listening'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KeywordTrainingScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(
    BuildContext context,
    RecordingState recordingState,
    KeywordTriggeredRecordingState keywordState,
  ) {
    final isAutoRecording = keywordState.isAutoRecording;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic_none_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Manual Recording',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recording button
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: recordingState.isRecording && !isAutoRecording
                      ? _pulseAnimation.value
                      : 1.0,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: FilledButton(
                      onPressed: isAutoRecording
                          ? null
                          : () {
                              if (recordingState.isRecording) {
                                _stopRecording();
                              } else {
                                _startRecording();
                              }
                            },
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: recordingState.isRecording
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        disabledBackgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      child: Icon(
                        recordingState.isRecording ? Icons.stop : Icons.mic,
                        size: 56,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Text(
              isAutoRecording
                  ? 'Auto-recording in progress\n(Triggered by keyword)'
                  : (recordingState.isRecording
                      ? 'Tap to stop recording'
                      : 'Tap to start recording'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

            if (recordingState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recordingState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecordingsListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Recordings'),
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryWarning(
    BuildContext context,
    BackgroundListeningState backgroundState,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_alert,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Battery low (${backgroundState.batteryLevel}%). Consider charging for continuous operation.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecordingsListScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Recordings',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    try {
      // Start manual recording with 10-minute auto-stop
      await ref.read(recordingProvider.notifier).startRecording(
            const Duration(minutes: 10),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started (10-minute auto-stop)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath =
          await ref.read(recordingProvider.notifier).stopRecording();
      if (mounted && recordingPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recording saved successfully'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordingsListScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
