import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_initialization_provider.dart';

/// Loading screen shown during app initialization
class AppLoadingScreen extends ConsumerWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);
    final progress = ref.watch(initializationProgressProvider);
    final error = ref.watch(initializationErrorProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App title
                Text(
                  'Voice Keyword Recorder',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Intelligent voice recording',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Loading content
                if (error != null) ...[
                  // Error state
                  _buildErrorState(context, ref, error),
                ] else ...[
                  // Loading state
                  _buildLoadingState(context, initState, progress),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(
    BuildContext context,
    AppInitializationState initState,
    double progress,
  ) {
    return Column(
      children: [
        // Progress indicator
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress percentage
        Text(
          '${(progress * 100).round()}%',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Loading status
        Text(
          _getLoadingMessage(initState),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Loading animation
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Column(
      children: [
        // Error icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2),
            border: Border.all(
              color: Colors.red.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red.shade300,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Error title
        Text(
          'Initialization Failed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Error message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Retry button
        ElevatedButton.icon(
          onPressed: () {
            ref.read(appInitializationProvider.notifier).retryInitialization();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  String _getLoadingMessage(AppInitializationState state) {
    if (!state.servicesReady) {
      return 'Initializing services...';
    } else if (!state.permissionsChecked) {
      return 'Checking permissions...';
    } else if (!state.settingsLoaded) {
      return 'Loading settings...';
    } else if (!state.recordingsLoaded) {
      return 'Loading recordings...';
    } else if (!state.isInitialized) {
      return 'Finalizing setup...';
    } else {
      return 'Ready!';
    }
  }
}