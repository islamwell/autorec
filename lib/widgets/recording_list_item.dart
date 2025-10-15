import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recording.dart';
import '../providers/recordings_provider.dart';
import '../services/service_locator.dart';
import 'compact_playback_controls.dart';

/// Widget representing a single recording in the list
class RecordingListItem extends ConsumerStatefulWidget {
  final Recording recording;
  final VoidCallback? onTap;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const RecordingListItem({
    super.key,
    required this.recording,
    this.onTap,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  ConsumerState<RecordingListItem> createState() => _RecordingListItemState();
}

class _RecordingListItemState extends ConsumerState<RecordingListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceVariant,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Column(
          children: [
            // Main content
            InkWell(
              onTap: widget.onTap ?? () => _toggleExpanded(),
              onLongPress: widget.onSelectionChanged != null
                  ? () => widget.onSelectionChanged!(!widget.isSelected)
                  : () => widget.onSelectionChanged?.call(true),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Selection checkbox (if selection mode is active)
                        if (widget.onSelectionChanged != null) ...[
                          Checkbox(
                            value: widget.isSelected,
                            onChanged: (value) => widget.onSelectionChanged!(value ?? false),
                            activeColor: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // Recording info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and keyword
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getRecordingTitle(),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.recording.keyword != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.tertiary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.tertiary.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        widget.recording.keyword!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.tertiary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Date and duration
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(widget.recording.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(widget.recording.duration),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.storage,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatFileSize(widget.recording.fileSize),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Expand/collapse button
                        IconButton(
                          onPressed: _toggleExpanded,
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    
                    // Playback controls (always visible)
                    const SizedBox(height: 12),
                    CompactPlaybackControls(
                      recording: widget.recording,
                      showProgress: true,
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded content (actions)
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildExpandedContent(theme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recording details
        _buildDetailRow(
          icon: Icons.high_quality,
          label: 'Quality',
          value: _getQualityText(widget.recording.quality),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.folder,
          label: 'File Path',
          value: widget.recording.filePath.split('/').last,
          theme: theme,
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            // Share button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareRecording,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Export button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportRecording,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Delete button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deleteRecording,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
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
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _shareRecording() async {
    try {
      final sharingService = ref.read(sharingServiceProvider);
      await sharingService.shareRecording(widget.recording, includeMetadata: true);
    } catch (e) {
      _showErrorSnackBar('Failed to share recording: ${e.toString()}');
    }
  }

  Future<void> _exportRecording() async {
    try {
      final sharingService = ref.read(sharingServiceProvider);
      final exportPath = await sharingService.exportToDownloads(widget.recording, format: 'mp3');
      
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
    }
  }

  Future<void> _deleteRecording() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      await ref.read(recordingsProvider.notifier).deleteRecording(widget.recording.id);
    }
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
    return nameWithoutExtension.isEmpty ? 'Recording ${widget.recording.id.substring(0, 8)}' : nameWithoutExtension;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Today $hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      return '$day/$month/$year';
    }
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