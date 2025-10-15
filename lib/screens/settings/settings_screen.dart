import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/background_listening_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/state_synchronization_provider.dart';
import '../../models/app_settings.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch state synchronization to ensure all providers are connected
    ref.watch(stateWatchersProvider);
    
    final settingsState = ref.watch(settingsProvider);
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
              _buildAppBar(context),
              
              // Settings content
              Expanded(
                child: settingsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recording Settings Section
                            _buildSectionHeader(context, 'Recording Settings'),
                            const SizedBox(height: 16),
                            _buildAutoStopDurationSetting(context, settingsState.settings),
                            const SizedBox(height: 16),
                            _buildRecordingQualitySetting(context, settingsState.settings),
                            
                            const SizedBox(height: 32),
                            
                            // Keyword Detection Section
                            _buildSectionHeader(context, 'Keyword Detection'),
                            const SizedBox(height: 16),
                            _buildKeywordListeningSetting(context, settingsState.settings, backgroundState),
                            const SizedBox(height: 16),
                            _buildBackgroundModeSetting(context, settingsState.settings),
                            
                            const SizedBox(height: 32),
                            
                            // Playback Settings Section
                            _buildSectionHeader(context, 'Playback Settings'),
                            const SizedBox(height: 16),
                            _buildPlaybackSpeedSetting(context, settingsState.settings),
                            
                            const SizedBox(height: 32),
                            
                            // App Information Section
                            _buildSectionHeader(context, 'App Information'),
                            const SizedBox(height: 16),
                            _buildAppInfoCard(context, backgroundState),
                            
                            const SizedBox(height: 32),
                            
                            // Reset Settings
                            _buildResetButton(context),
                            
                            // Error message
                            if (settingsState.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorMessage(context, settingsState.errorMessage!),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Configure your recording preferences',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAutoStopDurationSetting(BuildContext context, AppSettings settings) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Stop Duration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Recording stops automatically after this time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Duration slider
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${settings.autoStopDuration.inMinutes} minutes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '60 min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: settings.autoStopDuration.inMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier)
                          .updateAutoStopDuration(Duration(minutes: value.round()));
                    },
                  ),
                ),
              ],
            ),
            
            // Quick preset buttons
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPresetButton(context, '5 min', 5, settings.autoStopDuration.inMinutes == 5),
                const SizedBox(width: 8),
                _buildPresetButton(context, '15 min', 15, settings.autoStopDuration.inMinutes == 15),
                const SizedBox(width: 8),
                _buildPresetButton(context, '30 min', 30, settings.autoStopDuration.inMinutes == 30),
                const SizedBox(width: 8),
                _buildPresetButton(context, '60 min', 60, settings.autoStopDuration.inMinutes == 60),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String label, int minutes, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(settingsProvider.notifier)
              .updateAutoStopDuration(Duration(minutes: minutes));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingQualitySetting(BuildContext context, AppSettings settings) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.high_quality,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recording Quality',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Higher quality uses more storage space',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quality options
            ...AudioQuality.values.map((quality) {
              return _buildQualityOption(context, quality, settings.recordingQuality == quality);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(BuildContext context, AudioQuality quality, bool isSelected) {
    String title;
    String description;
    IconData icon;
    
    switch (quality) {
      case AudioQuality.low:
        title = 'Low Quality';
        description = 'Smaller file size, basic voice clarity';
        icon = Icons.signal_cellular_alt_1_bar;
        break;
      case AudioQuality.medium:
        title = 'Medium Quality';
        description = 'Balanced file size and voice clarity';
        icon = Icons.signal_cellular_alt_2_bar;
        break;
      case AudioQuality.high:
        title = 'High Quality';
        description = 'Larger file size, excellent voice clarity';
        icon = Icons.signal_cellular_4_bar;
        break;
    }

    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).updateRecordingQuality(quality);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordListeningSetting(
    BuildContext context,
    AppSettings settings,
    BackgroundListeningState backgroundState,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hearing,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyword Listening',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Automatically start recording when keyword is detected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.keywordListeningEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleKeywordListening(value);
                  },
                ),
              ],
            ),
            
            if (settings.keywordListeningEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundState.isListening
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: backgroundState.isListening
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      backgroundState.isListening
                          ? Icons.check_circle
                          : Icons.warning,
                      color: backgroundState.isListening
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        backgroundState.isListening
                            ? 'Currently listening for keywords'
                            : 'Keyword listening is paused',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: backgroundState.isListening
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
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

  Widget _buildBackgroundModeSetting(BuildContext context, AppSettings settings) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.settings_backup_restore,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Continue listening when app is in background',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.backgroundModeEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleBackgroundMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackSpeedSetting(BuildContext context, AppSettings settings) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Playback Speed',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Default speed for playing recordings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Speed slider
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0.5x',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${settings.playbackSpeed.toStringAsFixed(1)}x',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '2.0x',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: settings.playbackSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updatePlaybackSpeed(value);
                    },
                  ),
                ),
              ],
            ),
            
            // Speed preset buttons
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSpeedPresetButton(context, '0.5x', 0.5, settings.playbackSpeed == 0.5),
                const SizedBox(width: 8),
                _buildSpeedPresetButton(context, '1.0x', 1.0, settings.playbackSpeed == 1.0),
                const SizedBox(width: 8),
                _buildSpeedPresetButton(context, '1.5x', 1.5, settings.playbackSpeed == 1.5),
                const SizedBox(width: 8),
                _buildSpeedPresetButton(context, '2.0x', 2.0, settings.playbackSpeed == 2.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedPresetButton(BuildContext context, String label, double speed, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(settingsProvider.notifier).updatePlaybackSpeed(speed);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, BackgroundListeningState backgroundState) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(context, 'Battery Level', '${backgroundState.batteryLevel}%'),
            _buildInfoRow(context, 'Power Save Mode', backgroundState.isPowerSaveMode ? 'Enabled' : 'Disabled'),
            _buildInfoRow(context, 'Background Listening', backgroundState.isListening ? 'Active' : 'Inactive'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For best performance, disable battery optimization for this app in your device settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showResetConfirmationDialog(context);
        },
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              ref.read(settingsProvider.notifier).clearError();
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

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(settingsProvider.notifier).resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}