import 'dart:io';
import 'package:flutter/services.dart';

/// iOS-specific audio session configuration service
/// Handles proper audio session categories for recording and playback
class IOSAudioSessionService {
  static const MethodChannel _channel = MethodChannel('audio_session');
  
  /// Configure audio session for voice recording
  /// Sets up proper categories and options for background recording
  static Future<void> configureForRecording() async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('configureRecordingSession', {
        'category': 'AVAudioSessionCategoryPlayAndRecord',
        'mode': 'AVAudioSessionModeVoiceChat',
        'options': [
          'AVAudioSessionCategoryOptionDefaultToSpeaker',
          'AVAudioSessionCategoryOptionAllowBluetooth',
          'AVAudioSessionCategoryOptionAllowBluetoothA2DP',
        ],
      });
    } catch (e) {
      print('Failed to configure iOS audio session for recording: $e');
    }
  }
  
  /// Configure audio session for playback
  /// Optimizes for audio playback with proper routing
  static Future<void> configureForPlayback() async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('configurePlaybackSession', {
        'category': 'AVAudioSessionCategoryPlayback',
        'mode': 'AVAudioSessionModeDefault',
        'options': [
          'AVAudioSessionCategoryOptionAllowBluetooth',
          'AVAudioSessionCategoryOptionAllowBluetoothA2DP',
        ],
      });
    } catch (e) {
      print('Failed to configure iOS audio session for playback: $e');
    }
  }
  
  /// Configure audio session for background keyword detection
  /// Sets up minimal power consumption while maintaining audio monitoring
  static Future<void> configureForBackgroundListening() async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('configureBackgroundSession', {
        'category': 'AVAudioSessionCategoryRecord',
        'mode': 'AVAudioSessionModeVoiceChat',
        'options': [
          'AVAudioSessionCategoryOptionAllowBluetooth',
        ],
      });
    } catch (e) {
      print('Failed to configure iOS audio session for background: $e');
    }
  }
  
  /// Handle audio session interruptions (calls, other apps)
  /// Properly manages session activation and deactivation
  static Future<void> handleInterruption(bool began) async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('handleInterruption', {
        'began': began,
      });
    } catch (e) {
      print('Failed to handle iOS audio session interruption: $e');
    }
  }
  
  /// Activate audio session with proper error handling
  static Future<bool> activateSession() async {
    if (!Platform.isIOS) return true;
    
    try {
      final result = await _channel.invokeMethod('activateSession');
      return result as bool? ?? false;
    } catch (e) {
      print('Failed to activate iOS audio session: $e');
      return false;
    }
  }
  
  /// Deactivate audio session to allow other apps to use audio
  static Future<void> deactivateSession() async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('deactivateSession');
    } catch (e) {
      print('Failed to deactivate iOS audio session: $e');
    }
  }
}