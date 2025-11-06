import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scheduled_recording.dart' as models;
import '../../providers/scheduled_recording_provider.dart';

/// Screen for managing scheduled recordings
class ScheduledRecordingsScreen extends ConsumerWidget {
  const ScheduledRecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduledRecordingProvider);
    final notifier = ref.read(scheduledRecordingProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scheduled Recordings'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.recordings.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildRecordingsList(context, theme, state, notifier),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(context, notifier),
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Recordings',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first schedule',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(
    BuildContext context,
    ThemeData theme,
    ScheduledRecordingState state,
    ScheduledRecordingNotifier notifier,
  ) {
    return Column(
      children: [
        // Next recording info
        if (state.nextRecording != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Recording',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        state.nextRecording!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'at ${state.nextRecording!.formattedTime}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Recordings list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.recordings.length,
            itemBuilder: (context, index) {
              final recording = state.recordings[index];
              return _buildRecordingCard(context, theme, recording, notifier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingCard(
    BuildContext context,
    ThemeData theme,
    models.ScheduledRecording recording,
    ScheduledRecordingNotifier notifier,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: recording.isEnabled
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.schedule,
            color: recording.isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        title: Text(
          recording.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: recording.isEnabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${recording.formattedTime} • ${recording.formattedDuration}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: recording.isEnabled
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            if (!recording.isEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: recording.isEnabled,
              onChanged: (value) {
                notifier.toggleRecording(recording.id, value);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context, recording, notifier);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    ScheduledRecordingNotifier notifier,
  ) {
    final nameController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0); // Flutter's TimeOfDay
    int durationMinutes = 10;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Scheduled Recording'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Morning Meeting',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Time'),
                      subtitle: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                          ),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Duration'),
                      subtitle: Text(
                        '$durationMinutes minutes',
                        style: const TextStyle(fontSize: 18),
                      ),
                      trailing: const Icon(Icons.timer),
                    ),
                    Slider(
                      value: durationMinutes.toDouble(),
                      min: 1,
                      max: 120,
                      divisions: 119,
                      label: '$durationMinutes min',
                      onChanged: (value) {
                        setState(() {
                          durationMinutes = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a name'),
                        ),
                      );
                      return;
                    }

                    notifier.createRecording(
                      name: nameController.text.trim(),
                      time: models.TimeOfDay(
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                      ),
                      duration: Duration(minutes: durationMinutes),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    models.ScheduledRecording recording,
    ScheduledRecordingNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: Text('Are you sure you want to delete "${recording.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                notifier.deleteRecording(recording.id);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
