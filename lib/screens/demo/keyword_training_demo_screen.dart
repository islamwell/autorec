import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/keyword_profile.dart';
import '../../providers/keyword_training_provider.dart';
import '../../services/service_locator.dart';
import '../keyword_training/keyword_training_screen.dart';

/// Demo screen for testing keyword training functionality
class KeywordTrainingDemoScreen extends ConsumerStatefulWidget {
  const KeywordTrainingDemoScreen({super.key});

  @override
  ConsumerState<KeywordTrainingDemoScreen> createState() => _KeywordTrainingDemoScreenState();
}

class _KeywordTrainingDemoScreenState extends ConsumerState<KeywordTrainingDemoScreen> {
  List<KeywordProfile> _savedProfiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfiles();
  }

  Future<void> _loadSavedProfiles() async {
    setState(() => _isLoading = true);
    
    try {
      final profileService = ref.read(keywordProfileServiceProvider);
      final profiles = await profileService.loadAllProfiles();
      
      if (mounted) {
        setState(() {
          _savedProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(keywordTrainingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyword Training Demo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadSavedProfiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh profiles',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Training status card
                _buildTrainingStatusCard(trainingState),
                const SizedBox(height: 16),

                // Train new keyword button
                _buildTrainKeywordButton(),
                const SizedBox(height: 24),

                // Saved profiles section
                _buildSavedProfilesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingStatusCard(KeywordTrainingState trainingState) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Training Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Recording', trainingState.isRecording ? 'Active' : 'Inactive'),
            _buildStatusRow('Processing', trainingState.isProcessing ? 'Active' : 'Inactive'),
            if (trainingState.recordingDuration > Duration.zero)
              _buildStatusRow('Duration', _formatDuration(trainingState.recordingDuration)),
            if (trainingState.audioLevel > 0)
              _buildStatusRow('Audio Level', '${(trainingState.audioLevel * 100).toInt()}%'),
            if (trainingState.errorMessage != null)
              _buildStatusRow('Error', trainingState.errorMessage!, isError: true),
            if (trainingState.trainedProfile != null)
              _buildStatusRow('Last Trained', trainingState.trainedProfile!.keyword, isSuccess: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false, bool isSuccess = false}) {
    Color valueColor = Theme.of(context).colorScheme.onSurface;
    if (isError) valueColor = Colors.red;
    if (isSuccess) valueColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainKeywordButton() {
    return ElevatedButton(
      onPressed: _navigateToTraining,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline, size: 24),
          const SizedBox(width: 12),
          Text(
            'Train New Keyword',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedProfilesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Keywords',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedProfiles.isEmpty
                    ? _buildEmptyState()
                    : _buildProfilesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No keywords trained yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Train your first keyword to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesList() {
    return ListView.builder(
      itemCount: _savedProfiles.length,
      itemBuilder: (context, index) {
        final profile = _savedProfiles[index];
        return _buildProfileCard(profile);
      },
    );
  }

  Widget _buildProfileCard(KeywordProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.record_voice_over,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          profile.keyword,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Trained: ${_formatDate(profile.trainedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Confidence: ${(profile.confidence * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProfileAction(value, profile),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'activate',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTraining() async {
    final result = await Navigator.of(context).push<KeywordProfile>(
      MaterialPageRoute(
        builder: (context) => const KeywordTrainingScreen(),
      ),
    );

    if (result != null) {
      // Refresh the profiles list
      await _loadSavedProfiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keyword "${result.keyword}" trained successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleProfileAction(String action, KeywordProfile profile) async {
    switch (action) {
      case 'activate':
        await _activateProfile(profile);
        break;
      case 'delete':
        await _deleteProfile(profile);
        break;
    }
  }

  Future<void> _activateProfile(KeywordProfile profile) async {
    try {
      final profileService = ref.read(keywordProfileServiceProvider);
      await profileService.setActiveProfile(profile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activated keyword "${profile.keyword}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate keyword: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(KeywordProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Keyword'),
        content: Text('Are you sure you want to delete "${profile.keyword}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final profileService = ref.read(keywordProfileServiceProvider);
        await profileService.deleteProfile(profile.id);
        
        await _loadSavedProfiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted keyword "${profile.keyword}"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete keyword: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}