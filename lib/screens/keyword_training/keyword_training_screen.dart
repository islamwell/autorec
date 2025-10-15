import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/keyword_training_provider.dart';
import '../../widgets/audio_level_indicator.dart';

/// Screen for training custom keywords for voice detection
class KeywordTrainingScreen extends ConsumerStatefulWidget {
  const KeywordTrainingScreen({super.key});

  @override
  ConsumerState<KeywordTrainingScreen> createState() => _KeywordTrainingScreenState();
}

class _KeywordTrainingScreenState extends ConsumerState<KeywordTrainingScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _keywordFocusNode = FocusNode();
  bool _showInstructions = true;

  @override
  void dispose() {
    _keywordController.dispose();
    _keywordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(keywordTrainingProvider);
    final trainingNotifier = ref.read(keywordTrainingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Keyword'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions card
                if (_showInstructions) ...[
                  _buildInstructionsCard(),
                  const SizedBox(height: 24),
                ],

                // Keyword input
                _buildKeywordInput(trainingNotifier),
                const SizedBox(height: 32),

                // Recording section
                Expanded(
                  child: _buildRecordingSection(trainingState, trainingNotifier),
                ),

                // Action buttons
                _buildActionButtons(trainingState, trainingNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Train Your Keyword',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showInstructions = false),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep('1', 'Enter your keyword (1-5 words)'),
            _buildInstructionStep('2', 'Tap record and speak clearly'),
            _buildInstructionStep('3', 'Say your keyword 2-3 times'),
            _buildInstructionStep('4', 'Tap stop when finished'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordInput(KeywordTrainingNotifier trainingNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keyword',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          focusNode: _keywordFocusNode,
          decoration: InputDecoration(
            hintText: 'Enter your keyword (e.g., "Hey Assistant")',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (value) {
            // Clear any previous errors when user types
            ref.read(keywordTrainingProvider.notifier).clearError();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Use 1-5 words that are easy to pronounce clearly',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingSection(
    KeywordTrainingState trainingState,
    KeywordTrainingNotifier trainingNotifier,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio level indicator
        if (trainingState.isRecording) ...[
          AudioLevelIndicator(
            audioLevel: trainingState.audioLevel,
            isRecording: trainingState.isRecording,
          ),
          const SizedBox(height: 24),
        ],

        // Recording status
        _buildRecordingStatus(trainingState),
        
        const SizedBox(height: 32),

        // Record button
        _buildRecordButton(trainingState, trainingNotifier),

        // Error message
        if (trainingState.errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorMessage(trainingState.errorMessage!),
        ],

        // Success message
        if (trainingState.trainedProfile != null) ...[
          const SizedBox(height: 16),
          _buildSuccessMessage(trainingState.trainedProfile!.keyword),
        ],
      ],
    );
  }

  Widget _buildRecordingStatus(KeywordTrainingState trainingState) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (trainingState.isProcessing) {
      statusText = 'Processing keyword...';
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.hourglass_empty;
    } else if (trainingState.isRecording) {
      final duration = trainingState.recordingDuration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      statusText = 'Recording: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      statusColor = Colors.red;
      statusIcon = Icons.fiber_manual_record;
    } else if (trainingState.trainedProfile != null) {
      statusText = 'Keyword trained successfully!';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Ready to record';
      statusColor = Theme.of(context).colorScheme.onSurface;
      statusIcon = Icons.mic;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(statusIcon, color: statusColor, size: 24),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(
    KeywordTrainingState trainingState,
    KeywordTrainingNotifier trainingNotifier,
  ) {
    final isDisabled = trainingState.isProcessing || 
                     (trainingState.isRecording && _keywordController.text.trim().isEmpty);

    return GestureDetector(
      onTap: isDisabled ? null : () => _handleRecordButtonTap(trainingState, trainingNotifier),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDisabled
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : trainingState.isRecording
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          trainingState.isRecording ? Icons.stop : Icons.mic,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String keyword) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keyword "$keyword" trained successfully!',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    KeywordTrainingState trainingState,
    KeywordTrainingNotifier trainingNotifier,
  ) {
    return Column(
      children: [
        // Cancel button (when recording)
        if (trainingState.isRecording) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: trainingState.isProcessing 
                  ? null 
                  : () => trainingNotifier.cancelRecording(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancel Recording',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Done button (when training complete)
        if (trainingState.trainedProfile != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(trainingState.trainedProfile),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Use This Keyword',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => trainingNotifier.reset(),
            child: const Text('Train Another Keyword'),
          ),
        ],
      ],
    );
  }

  void _handleRecordButtonTap(
    KeywordTrainingState trainingState,
    KeywordTrainingNotifier trainingNotifier,
  ) {
    if (trainingState.isRecording) {
      // Stop recording
      final keywordText = _keywordController.text.trim();
      if (keywordText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a keyword before stopping'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validate keyword
      final validation = trainingNotifier.validateKeyword(keywordText);
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      trainingNotifier.stopAndProcessKeyword(keywordText);
    } else {
      // Start recording
      trainingNotifier.startRecording();
    }
  }
}