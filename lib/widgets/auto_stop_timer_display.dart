import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/recording_provider.dart';

/// Widget that displays the auto-stop timer during recording
class AutoStopTimerDisplay extends ConsumerWidget {
  const AutoStopTimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTimerActive = ref.watch(autoStopTimerActiveProvider);
    final remainingTime = ref.watch(autoStopRemainingTimeProvider);
    final isRecording = ref.watch(isRecordingProvider);

    // Only show timer if it's active and recording is in progress
    if (!isTimerActive || !isRecording) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400.withOpacity(0.2),
            Colors.red.shade400.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159, // Full rotation
                child: Icon(
                  Icons.timer,
                  color: Colors.orange.shade300,
                  size: 20,
                ),
              );
            },
          ),
          
          const SizedBox(width: 8),
          
          // Timer label
          Text(
            'Auto-stop in:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade300,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remaining time display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade400.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(remainingTime),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Progress indicator
          _buildProgressIndicator(context, remainingTime),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, Duration remainingTime) {
    // Calculate progress based on remaining time
    // Assuming max duration is from settings (we'll use a reasonable default)
    const maxDuration = Duration(minutes: 60); // Maximum possible duration
    final progress = 1.0 - (remainingTime.inSeconds / maxDuration.inSeconds);
    
    return Container(
      width: 40,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade300,
                Colors.red.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      // Format as HH:MM:SS for durations over an hour
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$hours:$minutes:$seconds';
    } else {
      // Format as MM:SS for durations under an hour
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes);
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }
  }
}

/// Compact version of the timer display for smaller spaces
class CompactAutoStopTimerDisplay extends ConsumerWidget {
  const CompactAutoStopTimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTimerActive = ref.watch(autoStopTimerActiveProvider);
    final remainingTime = ref.watch(autoStopRemainingTimeProvider);
    final isRecording = ref.watch(isRecordingProvider);

    // Only show timer if it's active and recording is in progress
    if (!isTimerActive || !isRecording) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade400.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.orange.shade300,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(remainingTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade300,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$hours:$minutes:$seconds';
    } else {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes);
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }
  }
}