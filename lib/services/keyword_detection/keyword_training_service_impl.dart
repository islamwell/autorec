import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../audio/audio_recording_service.dart';
import '../../models/keyword_profile.dart';
import 'keyword_training_service.dart';
import 'keyword_profile_service.dart';

/// Implementation of KeywordTrainingService for recording and processing keywords
class KeywordTrainingServiceImpl implements KeywordTrainingService {
  final AudioRecordingService _audioRecordingService;
  final KeywordProfileService _profileService;
  
  StreamSubscription<double>? _audioLevelSubscription;
  StreamController<double>? _audioLevelController;
  
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;

  KeywordTrainingServiceImpl(
    this._audioRecordingService,
    this._profileService,
  );

  @override
  Stream<double> get audioLevelStream => 
      _audioLevelController?.stream ?? const Stream.empty();

  @override
  bool get isRecording => _isRecording;

  @override
  Duration get recordingDuration {
    if (!_isRecording || _recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  @override
  Future<void> startKeywordRecording() async {
    if (_isRecording) {
      throw KeywordTrainingException('Keyword recording already in progress');
    }

    try {
      // Initialize audio level stream controller
      _audioLevelController = StreamController<double>.broadcast();
      
      // Configure audio service for voice recording
      await _audioRecordingService.configureForVoice();
      
      // Start recording
      await _audioRecordingService.startRecording();
      
      // Subscribe to audio levels for UI feedback
      _audioLevelSubscription = _audioRecordingService.audioLevelStream.listen(
        (level) => _audioLevelController?.add(level),
        onError: (error) => _audioLevelController?.addError(error),
      );
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      
    } catch (e) {
      await _cleanup();
      throw KeywordTrainingException(
        'Failed to start keyword recording: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<KeywordProfile> stopAndProcessKeyword(String keywordText) async {
    if (!_isRecording) {
      throw KeywordTrainingException('No keyword recording in progress');
    }

    try {
      // Validate keyword text
      final validation = validateKeyword(keywordText);
      if (!validation.isValid) {
        throw KeywordTrainingException(validation.errorMessage!);
      }

      // Stop recording and get the file path
      final recordingPath = await _audioRecordingService.stopRecording();
      _currentRecordingPath = recordingPath;
      
      // Process and save the keyword audio
      final processedPath = await _processKeywordAudio(recordingPath, keywordText);
      
      // Create keyword profile
      final profile = await _createKeywordProfile(keywordText, processedPath);
      
      // Cleanup
      await _cleanup();
      
      return profile;
      
    } catch (e) {
      await _cleanup();
      throw KeywordTrainingException(
        'Failed to process keyword: ${e.toString()}',
        e,
      );
    }
  }

  @override
  KeywordValidationResult validateKeyword(String keywordText) {
    // Remove leading/trailing whitespace
    final trimmed = keywordText.trim();
    
    // Check if empty
    if (trimmed.isEmpty) {
      return const KeywordValidationResult.invalid('Keyword cannot be empty');
    }
    
    // Check length (1-50 characters)
    if (trimmed.length > 50) {
      return const KeywordValidationResult.invalid('Keyword must be 50 characters or less');
    }
    
    // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes)
    final validPattern = RegExp(r"^[a-zA-Z0-9\s\-']+$");
    if (!validPattern.hasMatch(trimmed)) {
      return const KeywordValidationResult.invalid(
        'Keyword can only contain letters, numbers, spaces, hyphens, and apostrophes'
      );
    }
    
    // Check for reasonable word count (1-5 words)
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 5) {
      return const KeywordValidationResult.invalid('Keyword should be 5 words or less');
    }
    
    // Check minimum length per word
    for (final word in words) {
      if (word.length < 2) {
        return const KeywordValidationResult.invalid('Each word should be at least 2 characters');
      }
    }
    
    return const KeywordValidationResult.valid();
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return; // Nothing to cancel
    }

    try {
      // Stop recording without processing
      if (_audioRecordingService.isRecording) {
        await _audioRecordingService.stopRecording();
      }
      
      // Delete any temporary recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
    } catch (e) {
      // Log error but don't throw - cancellation should always succeed
      print('Warning: Error during recording cancellation: $e');
    } finally {
      await _cleanup();
    }
  }

  @override
  Future<void> dispose() async {
    await cancelRecording();
    await _audioLevelController?.close();
    _audioLevelController = null;
  }

  /// Process the recorded keyword audio for training
  Future<String> _processKeywordAudio(String recordingPath, String keywordText) async {
    try {
      // Get the keywords directory
      final keywordsDir = await _getKeywordsDirectory();
      
      // Generate filename based on keyword and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedKeyword = _sanitizeFilename(keywordText);
      final filename = 'keyword_${sanitizedKeyword}_$timestamp.wav';
      final processedPath = '${keywordsDir.path}/$filename';
      
      // Copy the recording to the keywords directory
      final sourceFile = File(recordingPath);
      
      await sourceFile.copy(processedPath);
      
      // Clean up the temporary recording
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
      
      return processedPath;
      
    } catch (e) {
      throw KeywordTrainingException(
        'Failed to process keyword audio: ${e.toString()}',
        e,
      );
    }
  }

  /// Create a keyword profile from the processed audio
  Future<KeywordProfile> _createKeywordProfile(String keywordText, String audioPath) async {
    try {
      final profileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final profile = KeywordProfile(
        id: profileId,
        keyword: keywordText.trim(),
        modelPath: audioPath,
        trainedAt: DateTime.now(),
        confidence: 0.7, // Default confidence threshold
      );
      
      // Save the profile using the profile service
      await _profileService.saveProfile(profile);
      
      return profile;
      
    } catch (e) {
      throw KeywordTrainingException(
        'Failed to create keyword profile: ${e.toString()}',
        e,
      );
    }
  }



  /// Get or create the keywords directory
  Future<Directory> _getKeywordsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final keywordsDir = Directory('${appDir.path}/keywords');
    
    if (!await keywordsDir.exists()) {
      await keywordsDir.create(recursive: true);
    }
    
    return keywordsDir;
  }

  /// Sanitize keyword text for use in filename
  String _sanitizeFilename(String keyword) {
    return keyword
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars except hyphens
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
  }

  /// Cleanup resources after recording
  Future<void> _cleanup() async {
    _isRecording = false;
    _recordingStartTime = null;
    _currentRecordingPath = null;
    
    await _audioLevelSubscription?.cancel();
    _audioLevelSubscription = null;
    
    await _audioLevelController?.close();
    _audioLevelController = null;
  }
}