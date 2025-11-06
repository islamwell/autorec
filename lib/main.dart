import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/service_configuration.dart';
import 'screens/home/simple_home_screen.dart';
import 'screens/recordings/recordings_list_screen.dart';
import 'screens/scheduling/scheduled_recordings_screen.dart';
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

class VoiceKeywordRecorderApp extends StatelessWidget {
  const VoiceKeywordRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Keyword Recorder',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SimpleHomeScreen(),
      routes: {
        '/recordings': (context) => const RecordingsListScreen(),
        '/scheduled-recordings': (context) => const ScheduledRecordingsScreen(),
      },
    );
  }
}