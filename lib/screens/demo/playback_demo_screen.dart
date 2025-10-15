import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/audio_playback_controls.dart';
import '../../providers/playback_provider.dart';

/// Demo screen for testing audio playback functionality
class PlaybackDemoScreen extends ConsumerStatefulWidget {
  const PlaybackDemoScreen({super.key});

  @override
  ConsumerState<PlaybackDemoScreen> createState() => _PlaybackDemoScreenState();
}

class _PlaybackDemoScreenState extends ConsumerState<PlaybackDemoScreen> {
  String? _selectedFilePath;
  final TextEditingController _filePathController = TextEditingController();

  @override
  void dispose() {
    _filePathController.dispose();
    super.dispose();
  }

  void _setFilePath() {
    final path = _filePathController.text.trim();
    if (path.isNotEmpty) {
      setState(() {
        _selectedFilePath = path;
      });
    }
  }

  void _clearFilePath() {
    setState(() {
      _selectedFilePath = null;
      _filePathController.clear();
    });
    // Stop any current playback
    ref.read(playbackProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Playback Demo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Playback Controls Demo',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test the audio playback functionality with speed controls and progress tracking.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // File path input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio File Path',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filePathController,
                      decoration: InputDecoration(
                        hintText: 'Enter path to an audio file (e.g., /path/to/audio.mp3)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _setFilePath,
                              icon: const Icon(Icons.check),
                              tooltip: 'Set file path',
                            ),
                            IconButton(
                              onPressed: _clearFilePath,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear file path',
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _setFilePath(),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedFilePath != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.audio_file,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: $_selectedFilePath',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Playback controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playback Controls',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AudioPlaybackControls(
                      filePath: _selectedFilePath,
                      onPlaybackComplete: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playback completed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Playback state information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playback State Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStateInfo('State', playbackState.state.name),
                    _buildStateInfo('Position', _formatDuration(playbackState.position)),
                    _buildStateInfo('Duration', playbackState.duration != null 
                        ? _formatDuration(playbackState.duration!) 
                        : 'Unknown'),
                    _buildStateInfo('Speed', '${playbackState.speed}x'),
                    if (playbackState.error != null)
                      _buildStateInfo('Error', playbackState.error!, isError: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Enter the path to an audio file (MP3, WAV, etc.)\n'
                      '2. Tap the check button to set the file path\n'
                      '3. Use the playback controls to play, pause, and control speed\n'
                      '4. Drag the progress bar to seek to different positions\n'
                      '5. Try different speed settings (0.5x to 2.0x)\n'
                      '6. Watch the state information update in real-time',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
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

  Widget _buildStateInfo(String label, String value, {bool isError = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isError 
                    ? theme.colorScheme.error 
                    : theme.colorScheme.onSurface,
                fontWeight: isError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}