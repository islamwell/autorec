import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recording_provider.dart';
import '../../providers/background_listening_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/state_synchronization_provider.dart';
import '../../widgets/audio_level_indicator.dart';
import '../recordings/recordings_list_screen.dart';
import '../settings/settings_screen.dart';

/// Main home screen with recording controls and status indicators
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _recordButtonController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _recordButtonAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _recordButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _recordButtonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch state synchronization to ensure all providers are connected
    ref.watch(stateWatchersProvider);
    
    final recordingState = ref.watch(recordingProvider);
    final backgroundState = ref.watch(backgroundListeningProvider);
    
    // Listen for global app errors
    ref.listen<String?>(appErrorProvider, (previous, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(appStateProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });
    
    // Control pulse animation based on recording state
    if (recordingState.isRecording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context, backgroundState),
              
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Status section
                      _buildStatusSection(context, recordingState, backgroundState),
                      
                      const SizedBox(height: 32),
                      
                      // Audio level indicator
                      if (recordingState.isInitialized)
                        AudioLevelIndicator(
                          audioLevel: recordingState.audioLevel,
                          qualityResult: recordingState.audioQuality,
                          isRecording: recordingState.isRecording,
                        ),
                      
                      const SizedBox(height: 16),
                      
                      const Spacer(),
                      
                      // Recording controls
                      _buildRecordingControls(context, recordingState),
                      
                      const SizedBox(height: 32),
                      
                      // Error message
                      if (recordingState.errorMessage != null)
                        _buildErrorMessage(context, recordingState.errorMessage!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildAppBar(BuildContext context, BackgroundListeningState backgroundState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // App title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Recorder',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Keyword-triggered recording',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Settings button
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundListeningIndicator(
    BuildContext context,
    BackgroundListeningState backgroundState,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundState.isListening
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundState.isListening
              ? Colors.green.shade300
              : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              backgroundState.isListening
                  ? Icons.hearing
                  : Icons.hearing_disabled,
              key: ValueKey(backgroundState.isListening),
              color: backgroundState.isListening
                  ? Colors.green.shade300
                  : Colors.grey.shade400,
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            backgroundState.isListening ? 'Listening' : 'Paused',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: backgroundState.isListening
                  ? Colors.green.shade300
                  : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    RecordingState recordingState,
    BackgroundListeningState backgroundState,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: Column(
          children: [
            // Recording status
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recordingState.isRecording
                        ? Colors.red.shade500
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recordingState.isRecording
                        ? 'Recording in progress'
                        : 'Ready to record',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recording duration and timer info
            if (recordingState.isRecording) ...[
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_formatDuration(recordingState.recordingDuration)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Battery and power save info
            Row(
              children: [
                Icon(
                  backgroundState.isPowerSaveMode
                      ? Icons.battery_saver
                      : Icons.battery_std,
                  color: backgroundState.batteryLevel < 20
                      ? Colors.red.shade400
                      : Colors.green.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery: ${backgroundState.batteryLevel}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (backgroundState.isPowerSaveMode) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Power Save',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context, RecordingState recordingState) {
    return Column(
      children: [
        // Main record button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: recordingState.isRecording ? _pulseAnimation.value : 1.0,
              child: AnimatedBuilder(
                animation: _recordButtonAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _recordButtonAnimation.value,
                    child: GestureDetector(
                      onTapDown: (_) => _recordButtonController.forward(),
                      onTapUp: (_) => _recordButtonController.reverse(),
                      onTapCancel: () => _recordButtonController.reverse(),
                      onTap: recordingState.isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: recordingState.isRecording
                              ? const LinearGradient(
                                  colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
                                )
                              : LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: (recordingState.isRecording
                                      ? Colors.red.shade600
                                      : Theme.of(context).colorScheme.primary)
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          recordingState.isRecording ? Icons.stop : Icons.mic,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Record button label
        Text(
          recordingState.isRecording ? 'Tap to stop recording' : 'Tap to start recording',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick action buttons
        if (!recordingState.isRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickActionButton(
                context,
                icon: Icons.list,
                label: 'Recordings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecordingsListScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.settings_voice,
                label: 'Keywords',
                onTap: () {
                  // TODO: Navigate to keyword training screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keyword training coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade400,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(recordingProvider.notifier).clearError();
            },
            icon: Icon(
              Icons.close,
              color: Colors.red.shade400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceVariant,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                context,
                icon: Icons.list,
                label: 'Recordings',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecordingsListScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                context,
                icon: Icons.settings,
                label: 'Settings',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    try {
      await ref.read(recordingProvider.notifier).startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await ref.read(recordingProvider.notifier).stopRecording();
      if (mounted && recordingPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recording saved successfully'),
            backgroundColor: Colors.green.shade600,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.of(context).push(
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
            content: Text('Failed to stop recording: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}