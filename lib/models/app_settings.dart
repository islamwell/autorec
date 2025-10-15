import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

/// Enum representing different audio quality levels
enum AudioQuality {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

/// Data model representing application settings and preferences
@JsonSerializable()
class AppSettings {
  /// Duration after which recording automatically stops
  final Duration autoStopDuration;
  
  /// Whether keyword listening is enabled
  final bool keywordListeningEnabled;
  
  /// Default playback speed multiplier (0.5x to 2.0x)
  final double playbackSpeed;
  
  /// Recording quality setting
  final AudioQuality recordingQuality;
  
  /// Whether background mode is enabled for keyword detection
  final bool backgroundModeEnabled;

  const AppSettings({
    required this.autoStopDuration,
    required this.keywordListeningEnabled,
    required this.playbackSpeed,
    required this.recordingQuality,
    required this.backgroundModeEnabled,
  });

  /// Default settings for new installations
  factory AppSettings.defaultSettings() {
    return const AppSettings(
      autoStopDuration: Duration(minutes: 15),
      keywordListeningEnabled: false,
      playbackSpeed: 1.0,
      recordingQuality: AudioQuality.medium,
      backgroundModeEnabled: false,
    );
  }

  /// Creates AppSettings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

  /// Converts AppSettings to JSON
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  /// Validation method to ensure settings are within valid ranges
  bool isValid() {
    // Auto-stop duration should be between 1 minute and 60 minutes
    if (autoStopDuration.inMinutes < 1 || autoStopDuration.inMinutes > 60) {
      return false;
    }
    
    // Playback speed should be between 0.5x and 2.0x
    if (playbackSpeed < 0.5 || playbackSpeed > 2.0) {
      return false;
    }
    
    return true;
  }

  /// Creates a copy of this settings with updated fields
  AppSettings copyWith({
    Duration? autoStopDuration,
    bool? keywordListeningEnabled,
    double? playbackSpeed,
    AudioQuality? recordingQuality,
    bool? backgroundModeEnabled,
  }) {
    return AppSettings(
      autoStopDuration: autoStopDuration ?? this.autoStopDuration,
      keywordListeningEnabled: keywordListeningEnabled ?? this.keywordListeningEnabled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      recordingQuality: recordingQuality ?? this.recordingQuality,
      backgroundModeEnabled: backgroundModeEnabled ?? this.backgroundModeEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.autoStopDuration == autoStopDuration &&
        other.keywordListeningEnabled == keywordListeningEnabled &&
        other.playbackSpeed == playbackSpeed &&
        other.recordingQuality == recordingQuality &&
        other.backgroundModeEnabled == backgroundModeEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      autoStopDuration,
      keywordListeningEnabled,
      playbackSpeed,
      recordingQuality,
      backgroundModeEnabled,
    );
  }

  @override
  String toString() {
    return 'AppSettings(autoStopDuration: $autoStopDuration, '
        'keywordListeningEnabled: $keywordListeningEnabled, '
        'playbackSpeed: $playbackSpeed, recordingQuality: $recordingQuality, '
        'backgroundModeEnabled: $backgroundModeEnabled)';
  }
}