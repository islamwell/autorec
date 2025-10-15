import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recording.dart';
import '../../providers/recordings_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/state_synchronization_provider.dart';
import '../../services/storage/recording_manager_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/recording_list_item.dart';
import 'recording_details_screen.dart';

/// Screen displaying the list of saved recordings with search and filter capabilities
class RecordingsListScreen extends ConsumerStatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  ConsumerState<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedRecordings = <String>{};
  bool _isSelectionMode = false;
  RecordingSortBy _currentSortBy = RecordingSortBy.dateCreated;
  SortOrder _currentSortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ref.read(recordingsProvider.notifier).loadRecordings();
    } else {
      ref.read(recordingsProvider.notifier).searchRecordings(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch state synchronization to ensure all providers are connected
    ref.watch(stateWatchersProvider);
    
    final theme = Theme.of(context);
    final recordingsState = ref.watch(recordingsProvider);
    final appState = ref.watch(appStateProvider);
    
    // Listen for errors and show snackbar
    ref.listen<String?>(recordingsErrorProvider, (previous, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: theme.colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(recordingsProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });
    
    // Listen for global app errors
    ref.listen<String?>(appErrorProvider, (previous, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: theme.colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(appStateProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: _buildAppBar(theme),
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
        child: Column(
          children: [
            // Search and filter section
            _buildSearchAndFilterSection(theme),
            
            // Recordings list
            Expanded(
              child: _buildRecordingsList(recordingsState, theme),
            ),
          ],
        ),
      ),
      
      // Floating action buttons
      floatingActionButton: _isSelectionMode ? _buildSelectionFAB(theme) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: _isSelectionMode
          ? Text('${_selectedRecordings.length} selected')
          : const Text('Recordings'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      actions: [
        if (_isSelectionMode) ...[
          // Select all button
          IconButton(
            onPressed: _selectAllRecordings,
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All',
          ),
          // Cancel selection button
          IconButton(
            onPressed: _exitSelectionMode,
            icon: const Icon(Icons.close),
            tooltip: 'Cancel Selection',
          ),
        ] else ...[
          // Sort button
          PopupMenuButton<String>(
            onSelected: _handleSortSelection,
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'date_asc',
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: 'duration_desc',
                child: Text('Longest First'),
              ),
              const PopupMenuItem(
                value: 'duration_asc',
                child: Text('Shortest First'),
              ),
              const PopupMenuItem(
                value: 'size_desc',
                child: Text('Largest First'),
              ),
              const PopupMenuItem(
                value: 'size_asc',
                child: Text('Smallest First'),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            onPressed: () => ref.read(recordingsProvider.notifier).refreshRecordings(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilterSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recordings...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        ref.read(recordingsProvider.notifier).loadRecordings();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Today', RecordingFilter.lastDays(1), theme),
                const SizedBox(width: 8),
                _buildFilterChip('This Week', RecordingFilter.lastDays(7), theme),
                const SizedBox(width: 8),
                _buildFilterChip('This Month', RecordingFilter.lastDays(30), theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RecordingFilter? filter, ThemeData theme) {
    final isSelected = _isFilterSelected(filter);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(recordingsProvider.notifier).applyFilter(selected ? filter : null);
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  bool _isFilterSelected(RecordingFilter? filter) {
    final currentFilter = ref.watch(recordingsProvider).currentFilter;
    
    if (filter == null && currentFilter == null) return true;
    if (filter == null || currentFilter == null) return false;
    
    // Simple comparison - in a real app you might want more sophisticated comparison
    return filter.startDate?.day == currentFilter.startDate?.day;
  }

  Widget _buildRecordingsList(RecordingsState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!state.hasRecordings) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(recordingsProvider.notifier).refreshRecordings(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: state.recordings.length,
        itemBuilder: (context, index) {
          final recording = state.recordings[index];
          final isSelected = _selectedRecordings.contains(recording.id);
          
          return RecordingListItem(
            recording: recording,
            isSelected: isSelected,
            onSelectionChanged: _isSelectionMode
                ? (selected) => _toggleRecordingSelection(recording.id, selected)
                : null,
            onTap: _isSelectionMode
                ? () => _toggleRecordingSelection(recording.id, !isSelected)
                : () => _navigateToDetails(recording),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recordings found',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start recording to see your audio files here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(recordingsProvider.notifier).refreshRecordings(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionFAB(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Share selected FAB
        if (_selectedRecordings.isNotEmpty) ...[
          FloatingActionButton(
            onPressed: _shareSelectedRecordings,
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            heroTag: 'share',
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 12),
        ],
        
        // Export selected FAB
        if (_selectedRecordings.isNotEmpty) ...[
          FloatingActionButton(
            onPressed: _exportSelectedRecordings,
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: Colors.white,
            heroTag: 'export',
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 12),
        ],
        
        // Delete selected FAB
        if (_selectedRecordings.isNotEmpty) ...[
          FloatingActionButton(
            onPressed: _deleteSelectedRecordings,
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            heroTag: 'delete',
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 16),
        ],
        
        // Select mode toggle FAB
        FloatingActionButton.extended(
          onPressed: _toggleSelectionMode,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          heroTag: 'select',
          icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
          label: Text(_isSelectionMode ? 'Cancel' : 'Select'),
        ),
      ],
    );
  }

  void _handleSortSelection(String value) {
    RecordingSortBy sortBy;
    SortOrder sortOrder;
    
    switch (value) {
      case 'date_desc':
        sortBy = RecordingSortBy.dateCreated;
        sortOrder = SortOrder.descending;
        break;
      case 'date_asc':
        sortBy = RecordingSortBy.dateCreated;
        sortOrder = SortOrder.ascending;
        break;
      case 'duration_desc':
        sortBy = RecordingSortBy.duration;
        sortOrder = SortOrder.descending;
        break;
      case 'duration_asc':
        sortBy = RecordingSortBy.duration;
        sortOrder = SortOrder.ascending;
        break;
      case 'size_desc':
        sortBy = RecordingSortBy.fileSize;
        sortOrder = SortOrder.descending;
        break;
      case 'size_asc':
        sortBy = RecordingSortBy.fileSize;
        sortOrder = SortOrder.ascending;
        break;
      default:
        return;
    }
    
    _currentSortBy = sortBy;
    _currentSortOrder = sortOrder;
    ref.read(recordingsProvider.notifier).changeSorting(sortBy, sortOrder);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRecordings.clear();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRecordings.clear();
    });
  }

  void _toggleRecordingSelection(String recordingId, bool selected) {
    setState(() {
      if (selected) {
        _selectedRecordings.add(recordingId);
      } else {
        _selectedRecordings.remove(recordingId);
      }
    });
  }

  void _selectAllRecordings() {
    final recordings = ref.read(recordingsListProvider);
    setState(() {
      _selectedRecordings.addAll(recordings.map((r) => r.id));
    });
  }

  Future<void> _deleteSelectedRecordings() async {
    if (_selectedRecordings.isEmpty) return;
    
    final confirmed = await _showDeleteConfirmation(_selectedRecordings.length);
    if (confirmed == true) {
      await ref.read(recordingsProvider.notifier).deleteMultipleRecordings(
        _selectedRecordings.toList(),
      );
      _exitSelectionMode();
    }
  }

  Future<bool?> _showDeleteConfirmation(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recordings'),
        content: Text(
          count == 1
              ? 'Are you sure you want to delete this recording?'
              : 'Are you sure you want to delete $count recordings?',
        ),
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
  
  void _navigateToDetails(Recording recording) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordingDetailsScreen(recording: recording),
      ),
    );
  }
  
  Future<void> _shareSelectedRecordings() async {
    if (_selectedRecordings.isEmpty) return;
    
    try {
      final recordings = ref.read(recordingsListProvider);
      final selectedRecordingObjects = recordings
          .where((r) => _selectedRecordings.contains(r.id))
          .toList();
      
      if (selectedRecordingObjects.isEmpty) return;
      
      // Show sharing options dialog
      final option = await _showSharingOptionsDialog(selectedRecordingObjects.length);
      if (option == null) return;
      
      final sharingService = ref.read(sharingServiceProvider);
      
      if (option == 'individual') {
        // Share individual files
        await sharingService.shareMultipleRecordings(
          selectedRecordingObjects,
          createZip: false,
          includeMetadata: true,
        );
      } else if (option == 'zip') {
        // Share as zip file
        await sharingService.shareMultipleRecordings(
          selectedRecordingObjects,
          createZip: true,
          includeMetadata: true,
        );
      }
      
      _exitSelectionMode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share recordings: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  Future<void> _exportSelectedRecordings() async {
    if (_selectedRecordings.isEmpty) return;
    
    try {
      final recordings = ref.read(recordingsListProvider);
      final selectedRecordingObjects = recordings
          .where((r) => _selectedRecordings.contains(r.id))
          .toList();
      
      if (selectedRecordingObjects.isEmpty) return;
      
      // Show export options dialog
      final options = await _showExportOptionsDialog(selectedRecordingObjects.length);
      if (options == null) return;
      
      final sharingService = ref.read(sharingServiceProvider);
      
      final exportPath = await sharingService.exportMultipleToDownloads(
        selectedRecordingObjects,
        format: options['format'] as String,
        createZip: options['createZip'] as bool,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recordings exported to: $exportPath'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
      
      _exitSelectionMode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export recordings: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  Future<String?> _showSharingOptionsDialog(int count) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share $count Recording${count > 1 ? 's' : ''}'),
        content: const Text('How would you like to share the selected recordings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('individual'),
            child: const Text('Individual Files'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('zip'),
            child: const Text('Zip Archive'),
          ),
        ],
      ),
    );
  }
  
  Future<Map<String, dynamic>?> _showExportOptionsDialog(int count) {
    String selectedFormat = 'mp3';
    bool createZip = count > 1;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Export $count Recording${count > 1 ? 's' : ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export format:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedFormat = value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                  DropdownMenuItem(value: 'wav', child: Text('WAV')),
                ],
              ),
              
              if (count > 1) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Create zip archive'),
                  subtitle: const Text('Combine all files into a single zip'),
                  value: createZip,
                  onChanged: (value) {
                    setState(() => createZip = value ?? false);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop({
                'format': selectedFormat,
                'createZip': createZip,
              }),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}