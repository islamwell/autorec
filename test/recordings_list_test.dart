import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_keyword_recorder/models/recording.dart';
import 'package:voice_keyword_recorder/widgets/recording_list_item.dart';
import 'package:voice_keyword_recorder/screens/recordings/recordings_list_screen.dart';
import 'package:voice_keyword_recorder/services/storage/recording_manager_service.dart';
import 'package:voice_keyword_recorder/services/service_locator.dart';
import 'package:voice_keyword_recorder/services/audio/audio_playback_service.dart';

// Mock audio playback service for testing
class MockAudioPlaybackService implements AudioPlaybackService {
  @override
  Future<void> play(String filePath) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Stream<Duration> get positionStream => Stream.value(Duration.zero);

  @override
  Stream<PlaybackState> get stateStream => Stream.value(PlaybackState.stopped);

  @override
  Duration? get duration => null;

  @override
  Duration get position => Duration.zero;

  @override
  PlaybackState get state => PlaybackState.stopped;

  @override
  double get speed => 1.0;

  @override
  Future<void> dispose() async {}
}

// Mock recording manager service for testing
class MockRecordingManagerService implements RecordingManagerService {
  final List<Recording> _recordings = [
    Recording(
      id: '1',
      filePath: '/test/recording1.mp3',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      duration: const Duration(minutes: 2, seconds: 30),
      keyword: 'test',
      fileSize: 1024 * 1024, // 1MB
      quality: RecordingQuality.high,
    ),
    Recording(
      id: '2',
      filePath: '/test/recording2.mp3',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      duration: const Duration(minutes: 1, seconds: 15),
      keyword: 'hello',
      fileSize: 512 * 1024, // 512KB
      quality: RecordingQuality.medium,
    ),
  ];

  @override
  Future<List<Recording>> getRecordings({
    RecordingFilter? filter,
    RecordingSortBy sortBy = RecordingSortBy.dateCreated,
    SortOrder sortOrder = SortOrder.descending,
    int? limit,
    int? offset,
  }) async {
    var recordings = List<Recording>.from(_recordings);
    
    // Apply sorting
    recordings.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case RecordingSortBy.dateCreated:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case RecordingSortBy.duration:
          comparison = a.duration.compareTo(b.duration);
          break;
        case RecordingSortBy.fileSize:
          comparison = a.fileSize.compareTo(b.fileSize);
          break;
        case RecordingSortBy.keyword:
          comparison = (a.keyword ?? '').compareTo(b.keyword ?? '');
          break;
        case RecordingSortBy.alphabetical:
          comparison = a.filePath.compareTo(b.filePath);
          break;
      }
      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    return recordings;
  }

  @override
  Future<Recording?> getRecording(String id) async {
    try {
      return _recordings.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteRecording(String id) async {
    _recordings.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<Recording>> searchRecordings(String query, {int? limit}) async {
    final queryLower = query.toLowerCase();
    return _recordings.where((r) {
      return (r.keyword?.toLowerCase().contains(queryLower) ?? false) ||
             r.filePath.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Implement other required methods with basic functionality
  @override
  Future<Recording> createRecording(String tempPath, Map<String, dynamic> metadata) async {
    throw UnimplementedError();
  }

  @override
  Future<Recording> updateRecording(String id, Map<String, dynamic> updates) async {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteMultipleRecordings(List<String> ids) async {
    int count = 0;
    for (final id in ids) {
      if (_recordings.any((r) => r.id == id)) {
        _recordings.removeWhere((r) => r.id == id);
        count++;
      }
    }
    return count;
  }

  @override
  Future<RecordingStatistics> getStatistics({RecordingFilter? filter}) async {
    throw UnimplementedError();
  }

  @override
  Future<StorageInfo> getStorageInfo() async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, List<Recording>>> getRecordingsByKeyword() async {
    throw UnimplementedError();
  }

  @override
  Future<Map<DateTime, List<Recording>>> getRecordingsByDate() async {
    throw UnimplementedError();
  }

  @override
  Future<String> exportRecording(String id, {String format = 'mp3'}) async {
    return '/exported/recording_$id.$format';
  }

  @override
  Future<String> exportMultipleRecordings(List<String> ids, {String format = 'mp3'}) async {
    throw UnimplementedError();
  }

  @override
  Future<int> cleanupOldRecordings({int? olderThanDays, int? keepMinimum}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> createBackup() async {
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromBackup(String backupPath) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateRecording(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> validateAllRecordings() async {
    throw UnimplementedError();
  }

  @override
  Future<List<List<Recording>>> findDuplicateRecordings() async {
    throw UnimplementedError();
  }
}

void main() {
  group('RecordingsListScreen Tests', () {
    late MockRecordingManagerService mockRecordingService;
    late MockAudioPlaybackService mockPlaybackService;

    setUp(() {
      mockRecordingService = MockRecordingManagerService();
      mockPlaybackService = MockAudioPlaybackService();
    });

    testWidgets('displays empty state when no recordings', (WidgetTester tester) async {
      // Override the mock to return empty list
      final emptyMockService = MockRecordingManagerService();
      emptyMockService._recordings.clear();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(emptyMockService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      // Wait for the recordings to load
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Recordings'), findsOneWidget);
      expect(find.text('No recordings found'), findsOneWidget);
    });

    testWidgets('displays recordings list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(mockRecordingService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      // Wait for the recordings to load
      await tester.pumpAndSettle();

      // Verify that recordings are displayed
      expect(find.text('Recordings'), findsOneWidget);
      expect(find.byType(Card), findsAtLeast(2)); // Should find recording cards
    });

    testWidgets('search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(mockRecordingService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Verify search results (should show only recordings matching 'test')
      // This is a basic test - in a real scenario you'd verify specific recordings
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('sort functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(mockRecordingService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the sort button
      final sortButton = find.byIcon(Icons.sort);
      expect(sortButton, findsOneWidget);

      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Verify sort menu appears
      expect(find.text('Newest First'), findsOneWidget);
      expect(find.text('Oldest First'), findsOneWidget);

      // Tap a sort option
      await tester.tap(find.text('Oldest First'));
      await tester.pumpAndSettle();

      // Verify recordings are still displayed (sorting applied)
      expect(find.byType(Card), findsAtLeast(2));
    });

    testWidgets('refresh functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(mockRecordingService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Verify recordings are still displayed after refresh
      expect(find.byType(Card), findsAtLeast(2));
    });

    testWidgets('filter chips work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingManagerServiceProvider.overrideWithValue(mockRecordingService),
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: const RecordingsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      // Tap a filter chip
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify the filter is applied (recordings still displayed)
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('RecordingListItem Tests', () {
    late MockAudioPlaybackService mockPlaybackService;
    late Recording testRecording;

    setUp(() {
      mockPlaybackService = MockAudioPlaybackService();
      testRecording = Recording(
        id: 'test-1',
        filePath: '/test/recording.mp3',
        createdAt: DateTime.now(),
        duration: const Duration(minutes: 2, seconds: 30),
        keyword: 'test',
        fileSize: 1024 * 1024, // 1MB
        quality: RecordingQuality.high,
      );
    });

    testWidgets('displays recording information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RecordingListItem(recording: testRecording),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify recording information is displayed
      expect(find.text('test'), findsOneWidget); // keyword chip
      expect(find.text('2m 30s'), findsOneWidget); // duration
      expect(find.text('1.0 MB'), findsOneWidget); // file size
    });

    testWidgets('expands to show actions when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlaybackServiceProvider.overrideWithValue(mockPlaybackService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RecordingListItem(recording: testRecording),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, action buttons should not be visible
      expect(find.text('Share'), findsNothing);
      expect(find.text('Export'), findsNothing);
      expect(find.text('Delete'), findsNothing);

      // Tap the expand button
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Now action buttons should be visible
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}