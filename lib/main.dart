import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/service_configuration.dart';
import 'widgets/permission_wrapper.dart';
import 'screens/home/home_screen.dart';
import 'screens/loading/app_loading_screen.dart';

import 'providers/app_initialization_provider.dart';
import 'screens/demo/permission_demo_screen.dart';
import 'screens/demo/playback_demo_screen.dart';
import 'screens/demo/keyword_detection_demo_screen.dart';
import 'screens/demo/keyword_training_demo_screen.dart';
import 'screens/demo/background_listening_demo_screen.dart';
import 'screens/demo/theme_demo_screen.dart';
import 'screens/recordings/recordings_list_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services and get provider overrides
  final overrides = await ServiceConfiguration.initializeServices();
  
  runApp(
    ProviderScope(
      overrides: overrides,
      child: const VoiceKeywordRecorderApp(),
    ),
  );
}

class VoiceKeywordRecorderApp extends ConsumerWidget {
  const VoiceKeywordRecorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize state providers
    ref.watch(stateProvidersInitializationProvider);
    
    // Check if app is ready
    final isAppReady = ref.watch(appReadyProvider);
    
    return MaterialApp(
      title: 'Voice Keyword Recorder',
      theme: AppTheme.darkTheme,
      home: isAppReady
          ? const AppPermissionWrapper(
              child: HomeScreen(),
            )
          : const AppLoadingScreen(),
    );
  }


}

// Placeholder home screen for now - will be replaced in later tasks
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Keyword Recorder'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Voice Keyword Recorder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Permission system implemented',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PermissionDemoScreen(),
                  ),
                );
              },
              child: const Text('Test Permissions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaybackDemoScreen(),
                  ),
                );
              },
              child: const Text('Test Audio Playback'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const KeywordDetectionDemoScreen(),
                  ),
                );
              },
              child: const Text('Test Keyword Detection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const KeywordTrainingDemoScreen(),
                  ),
                );
              },
              child: const Text('Train Keywords'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BackgroundListeningDemoScreen(),
                  ),
                );
              },
              child: const Text('Test Background Listening'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RecordingsListScreen(),
                  ),
                );
              },
              child: const Text('View Recordings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemeDemoScreen(),
                  ),
                );
              },
              child: const Text('Theme Demo'),
            ),
          ],
        ),
      ),
    );
  }
}