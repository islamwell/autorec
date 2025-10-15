import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/background_listening_provider.dart';
import '../../services/service_locator.dart';
import '../../models/app_settings.dart';

/// Demo screen for testing background listening functionality
class BackgroundListeningDemoScreen extends ConsumerStatefulWidget {
  const BackgroundListeningDemoScreen({super.key});

  @override
  ConsumerState<BackgroundListeningDemoScreen> createState() => _BackgroundListeningDemoScreenState();
}

class _BackgroundListeningDemoScreenState extends ConsumerState<BackgroundListeningDemoScreen> {
  bool _backgroundModeEnabled = false;
  bool _keywordListeningEnabled = true;
  Duration _autoStopDuration = const Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final backgroundState = ref.watch(backgroundListeningProvider);
    final backgroundNotifier = ref.read(backgroundListeningProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Listening Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background Listening Status',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow('Initialized', backgroundState.isInitialized),
                    _buildStatusRow('Listening', backgroundState.isListening),
                    _buildStatusRow('Battery Level', '${backgroundState.batteryLevel}%'),
                    _buildStatusRow('Power Save Mode', backgroundState.isPowerSaveMode),
                    if (backgroundState.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Error: ${backgroundState.errorMessage}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background Settings',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Background Mode Toggle
                    SwitchListTile(
                      title: const Text('Background Mode Enabled'),
                      subtitle: const Text('Allow app to run in background'),
                      value: _backgroundModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _backgroundModeEnabled = value;
                        });
                      },
                    ),
                    
                    // Keyword Listening Toggle
                    SwitchListTile(
                      title: const Text('Keyword Listening'),
                      subtitle: const Text('Listen for keywords in background'),
                      value: _keywordListeningEnabled,
                      onChanged: (value) {
                        setState(() {
                          _keywordListeningEnabled = value;
                        });
                      },
                    ),
                    
                    // Auto-stop Duration
                    ListTile(
                      title: const Text('Auto-stop Duration'),
                      subtitle: Text('${_autoStopDuration.inMinutes} minutes'),
                      trailing: DropdownButton<Duration>(
                        value: _autoStopDuration,
                        items: const [
                          DropdownMenuItem(
                            value: Duration(minutes: 5),
                            child: Text('5 min'),
                          ),
                          DropdownMenuItem(
                            value: Duration(minutes: 15),
                            child: Text('15 min'),
                          ),
                          DropdownMenuItem(
                            value: Duration(minutes: 30),
                            child: Text('30 min'),
                          ),
                          DropdownMenuItem(
                            value: Duration(minutes: 60),
                            child: Text('60 min'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _autoStopDuration = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Controls',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Apply Settings Button
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final settings = AppSettings(
                            autoStopDuration: _autoStopDuration,
                            keywordListeningEnabled: _keywordListeningEnabled,
                            backgroundModeEnabled: _backgroundModeEnabled,
                            playbackSpeed: 1.0,
                            recordingQuality: AudioQuality.high,
                          );
                          
                          await backgroundNotifier.configureSettings(settings);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings applied successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to apply settings: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Apply Settings'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Start/Stop Background Listening
                    ElevatedButton(
                      onPressed: backgroundState.isListening
                          ? () async {
                              try {
                                await backgroundNotifier.stopBackgroundListening();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Background listening stopped'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to stop: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : () async {
                              try {
                                await backgroundNotifier.startBackgroundListening();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Background listening started'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to start: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundState.isListening
                            ? Colors.red
                            : Colors.green,
                      ),
                      child: Text(
                        backgroundState.isListening
                            ? 'Stop Background Listening'
                            : 'Start Background Listening',
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Setup Platform Background Mode
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await backgroundNotifier.setupPlatformBackgroundMode();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Platform background mode configured'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to setup platform mode: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Setup Platform Background Mode'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Clear Error Button
                    if (backgroundState.errorMessage != null)
                      ElevatedButton(
                        onPressed: () {
                          backgroundNotifier.clearError();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('Clear Error'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Battery and Power Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Information',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Battery Level Indicator
                    Row(
                      children: [
                        Icon(
                          backgroundState.batteryLevel > 50
                              ? Icons.battery_full
                              : backgroundState.batteryLevel > 20
                                  ? Icons.battery_3_bar
                                  : Icons.battery_1_bar,
                          color: backgroundState.batteryLevel > 20
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text('Battery: ${backgroundState.batteryLevel}%'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Power Save Mode Indicator
                    Row(
                      children: [
                        Icon(
                          backgroundState.isPowerSaveMode
                              ? Icons.power_settings_new
                              : Icons.power,
                          color: backgroundState.isPowerSaveMode
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          backgroundState.isPowerSaveMode
                              ? 'Power Save Mode: ON'
                              : 'Power Save Mode: OFF',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistics Button
                    ElevatedButton(
                      onPressed: () {
                        _showBackgroundStats(context);
                      },
                      child: const Text('View Background Statistics'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    Color statusColor;
    if (value is bool) {
      statusColor = value ? Colors.green : Colors.red;
    } else {
      statusColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackgroundStats(BuildContext context) {
    final backgroundService = ref.read(backgroundListeningServiceProvider);
    final stats = backgroundService.getBackgroundListeningStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Listening Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Status', stats['isListening'] ? 'Active' : 'Inactive'),
              if (stats['listeningStartTime'] != null)
                _buildStatRow('Started At', stats['listeningStartTime']),
              if (stats['listeningDuration'] != null)
                _buildStatRow('Duration', '${stats['listeningDuration']} seconds'),
              _buildStatRow('Keywords Detected', '${stats['keywordDetectionCount']}'),
              _buildStatRow('Background Tasks', '${stats['backgroundTaskExecutions']}'),
              _buildStatRow('Battery Monitoring', stats['batteryLevel']),
              _buildStatRow('Power Save Monitoring', stats['powerSaveMode']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}