import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recording.dart';
import '../../providers/recordings_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/audio_playback_controls.dart';

/// Screen showing detailed information about a recording with sharing options
class RecordingDetailsScreen extends ConsumerStatefulWidget {
  final Recording recording;
  
  const RecordingDetailsScreen({
    super.key,
    required this.recording,
  });
  
  @override
  ConsumerState<RecordingDetailsScreen> createState() => _RecordingDetailsScreenState();
}

class _RecordingDetailsScreenState extends ConsumerState<RecordingDetailsScreen> {
  bool _isExporting = false;
  bool _isSharing = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getRecordingTitle()),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        actions: [
          // More options menu
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'properties',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Properties'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recording info card
              _buildInfoCard(theme),
              
              const SizedBox(height: 16),
              
              // Playback controls
              _buildPlaybackCard(theme),
              
              const SizedBox(height: 16),
              
              // Sharing options
              _buildSharingCard(theme),
              
              const SizedBox(height: 16),
              
              // File management
              _buildFileManagementCard(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getRecordingTitle(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Keyword badge
            if (widget.recording.keyword != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.recording.keyword!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Details grid
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Duration',
              value: _formatDuration(widget.recording.duration),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Created',
              value: _formatDateTime(widget.recording.createdAt),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.high_quality,
              label: 'Quality',
              value: _getQualityText(widget.recording.quality),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.storage,
              label: 'File Size',
              value: _formatFileSize(widget.recording.fileSize),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.folder,
              label: 'Format',
              value: _getFileFormat(),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaybackCard(ThemeData theme) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Playback',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Full playback controls
            AudioPlaybackControls(
              filePath: widget.recording.filePath,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSharingCard(ThemeData theme) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withOpacity(0.1),
              theme.colorScheme.tertiary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.share,
                  color: theme.colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sharing Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sharing buttons grid
            Row(
              children: [
                // Share button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: _isSharing ? null : _shareRecording,
                    backgroundColor: theme.colorScheme.primary,
                    isLoading: _isSharing,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Export MP3 button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download,
                    label: 'Export MP3',
                    onPressed: _isExporting ? null : () => _exportRecording('mp3'),
                    backgroundColor: theme.colorScheme.secondary,
                    isLoading: _isExporting,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Additional export options
            Row(
              children: [
                // Export WAV button (if available)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.audio_file,
                    label: 'Export WAV',
                    onPressed: _getFileFormat().toLowerCase() == 'wav' 
                        ? () => _exportRecording('wav')
                        : null,
                    backgroundColor: theme.colorScheme.tertiary,
                    isLoading: false,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Share with metadata button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.info_outline,
                    label: 'Share Details',
                    onPressed: _shareWithDetails,
                    backgroundColor: theme.colorScheme.outline,
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFileManagementCard(ThemeData theme) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceVariant,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'File Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // File management buttons
            Row(
              children: [
                // Move to folder button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.drive_file_move,
                    label: 'Move',
                    onPressed: _moveRecording,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.7),
                    isLoading: false,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Delete button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    onPressed: _deleteRecording,
                    backgroundColor: theme.colorScheme.error,
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required bool isLoading,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog();
        break;
      case 'duplicate':
        _duplicateRecording();
        break;
      case 'properties':
        _showPropertiesDialog();
        break;
    }
  }
  
  Future<void> _shareRecording() async {
    setState(() => _isSharing = true);
    
    try {
      final sharingService = ref.read(sharingServiceProvider);
      await sharingService.shareRecording(widget.recording, includeMetadata: true);
    } catch (e) {
      _showErrorSnackBar('Failed to share recording: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
  
  Future<void> _exportRecording(String format) async {
    setState(() => _isExporting = true);
    
    try {
      final sharingService = ref.read(sharingServiceProvider);
      final exportPath = await sharingService.exportToDownloads(
        widget.recording,
        format: format,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording exported to: $exportPath'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export recording: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
  
  Future<void> _shareWithDetails() async {
    try {
      final details = _buildRecordingDetails();
      
      // Show dialog with sharing options
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Recording Details'),
          content: SingleChildScrollView(
            child: Text(details),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareTextDetails(details);
              },
              child: const Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share details: ${e.toString()}');
    }
  }
  
  Future<void> _shareTextDetails(String details) async {
    try {
      final sharingService = ref.read(sharingServiceProvider);
      // For text sharing, we can use the platform share functionality
      // This is a simplified implementation - in a real app you might want to use Share.share
      await sharingService.shareRecording(widget.recording, includeMetadata: true);
    } catch (e) {
      _showErrorSnackBar('Failed to share text details: ${e.toString()}');
    }
  }
  
  Future<void> _moveRecording() async {
    // This would show a folder selection dialog
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Move functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _deleteRecording() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      try {
        await ref.read(recordingsProvider.notifier).deleteRecording(widget.recording.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to recordings list
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete recording: ${e.toString()}');
      }
    }
  }
  
  Future<void> _showRenameDialog() async {
    // This would show a rename dialog
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rename functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _duplicateRecording() async {
    // This would create a copy of the recording
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _showPropertiesDialog() async {
    final details = _buildRecordingDetails();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Properties'),
        content: SingleChildScrollView(
          child: Text(details),
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
  
  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  String _getRecordingTitle() {
    final fileName = widget.recording.filePath.split('/').last;
    final nameWithoutExtension = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    return nameWithoutExtension.isEmpty 
        ? 'Recording ${widget.recording.id.substring(0, 8)}' 
        : nameWithoutExtension;
  }
  
  String _getFileFormat() {
    final extension = widget.recording.filePath.split('.').last.toUpperCase();
    return extension.isEmpty ? 'Unknown' : extension;
  }
  
  String _buildRecordingDetails() {
    final buffer = StringBuffer();
    
    buffer.writeln('Recording Details');
    buffer.writeln('================');
    buffer.writeln();
    buffer.writeln('Title: ${_getRecordingTitle()}');
    
    if (widget.recording.keyword != null) {
      buffer.writeln('Keyword: ${widget.recording.keyword}');
    }
    
    buffer.writeln('Duration: ${_formatDuration(widget.recording.duration)}');
    buffer.writeln('Created: ${_formatDateTime(widget.recording.createdAt)}');
    buffer.writeln('Quality: ${_getQualityText(widget.recording.quality)}');
    buffer.writeln('File Size: ${_formatFileSize(widget.recording.fileSize)}');
    buffer.writeln('Format: ${_getFileFormat()}');
    buffer.writeln('ID: ${widget.recording.id}');
    
    return buffer.toString();
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year at $hour:$minute';
  }
  
  String _formatFileSize(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toInt()} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  String _getQualityText(RecordingQuality quality) {
    switch (quality) {
      case RecordingQuality.low:
        return 'Low';
      case RecordingQuality.medium:
        return 'Medium';
      case RecordingQuality.high:
        return 'High';
    }
  }
}