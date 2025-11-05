import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/service_configuration.dart';
import 'widgets/permission_wrapper.dart';
import 'screens/home/improved_home_screen.dart';
import 'screens/loading/app_loading_screen.dart';
import 'providers/app_initialization_provider.dart';
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
      debugShowCheckedModeBanner: false,
      home: isAppReady
          ? const AppPermissionWrapper(
              child: ImprovedHomeScreen(),
            )
          : const AppLoadingScreen(),
    );
  }
}