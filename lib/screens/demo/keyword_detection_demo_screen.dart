import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_locator.dart';
import '../../models/keyword_profile.dart';

/// Demo screen for testing keyword detection functionality
class KeywordDetectionDemoScreen extends ConsumerStatefulWidget {
  const KeywordDetectionDemoScreen({super.key});

  @override
  ConsumerState<KeywordDetectionDemoScreen> createState() => _KeywordDetectionDemoScreenState();
}

class _KeywordDetectionDemoScreenState extends ConsumerState<KeywordDetectionDemoScreen> {
  bool _isListening = false;
  bool _keywordDetected = false;
  double _confidence = 0.0;
  KeywordProfile? _currentProfile;
  String _statusMessage = 'Ready to start';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final keywordService = ref.read(keywordDetectionServiceProvider);
    
    // Listen for keyword detection
    keywordService.keywordDetectedStream.listen((detected) {
      if (mounted) {
        setState(() {
          _keywordDetected = detected;
          if (detected) {
            _statusMessage = 'Keyword detected!';
          }
        });
      }
    });

    // Listen for confidence updates
    keywordService.confidenceStream.listen((confidence) {
      if (mounted) {
        setState(() {
          _confidence = confidence;
        });
      }
    });
  }

  Future<void> _startListening() async {
    try {
      final keywordService = ref.read(keywordDetectionServiceProvider);
      
      if (_currentProfile == null) {
        setState(() {
          _statusMessage = 'No keyword profile loaded. Train a keyword first.';
        });
        return;
      }

      await keywordService.startListening();
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening for keyword...';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting listening: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      final keywordService = ref.read(keywordDetectionServiceProvider);
      await keywordService.stopListening();
      setState(() {
        _isListening = false;
        _statusMessage = 'Stopped listening';
        _keywordDetected = false;
        _confidence = 0.0;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping listening: $e';
      });
    }
  }

  Future<void> _trainKeyword() async {
    try {
      setState(() {
        _statusMessage = 'Training keyword (simulated)...';
      });

      // Simulate keyword training with a dummy audio file path
      // In real implementation, this would record actual audio
      final keywordService = ref.read(keywordDetectionServiceProvider);
      
      // Create a dummy audio file path for testing
      final dummyAudioPath = '/tmp/dummy_keyword.wav';
      
      try {
        final profile = await keywordService.trainKeyword(dummyAudioPath);
        setState(() {
          _currentProfile = profile;
          _statusMessage = 'Keyword trained successfully!';
        });
      } catch (e) {
        // Expected to fail since we're using a dummy path
        // Create a mock profile for demo purposes
        final mockProfile = KeywordProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          keyword: 'test_keyword',
          modelPath: dummyAudioPath,
          trainedAt: DateTime.now(),
          confidence: 0.7,
        );
        
        final keywordService = ref.read(keywordDetectionServiceProvider);
        await keywordService.updateConfidenceThreshold(0.7);
        
        setState(() {
          _currentProfile = mockProfile;
          _statusMessage = 'Mock keyword profile created for demo';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error training keyword: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyword Detection Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: _isListening ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_isListening ? 'Listening' : 'Not listening'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Keyword Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keyword Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_currentProfile != null) ...[
                      Text('ID: ${_currentProfile!.id}'),
                      Text('Keyword: ${_currentProfile!.keyword}'),
                      Text('Confidence: ${_currentProfile!.confidence.toStringAsFixed(2)}'),
                      Text('Trained: ${_currentProfile!.trainedAt.toString().substring(0, 19)}'),
                    ] else ...[
                      const Text('No keyword profile loaded'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _keywordDetected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _keywordDetected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_keywordDetected ? 'Keyword Detected!' : 'No detection'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Confidence: ${_confidence.toStringAsFixed(3)}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _confidence,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _confidence > 0.7 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Control Buttons
            ElevatedButton(
              onPressed: _trainKeyword,
              child: const Text('Train Keyword (Demo)'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _currentProfile == null ? null : (_isListening ? _stopListening : _startListening),
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
            
            const Spacer(),
            
            // Info Text
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This is a demo of the basic keyword detection service structure. '
                  'The service implements audio buffer management and simple pattern matching '
                  'as a foundation for future ML integration.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}