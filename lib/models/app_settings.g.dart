// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  autoStopDuration: Duration(
    microseconds: (json['autoStopDuration'] as num).toInt(),
  ),
  keywordListeningEnabled: json['keywordListeningEnabled'] as bool,
  playbackSpeed: (json['playbackSpeed'] as num).toDouble(),
  recordingQuality: $enumDecode(
    _$AudioQualityEnumMap,
    json['recordingQuality'],
  ),
  backgroundModeEnabled: json['backgroundModeEnabled'] as bool,
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'autoStopDuration': instance.autoStopDuration.inMicroseconds,
      'keywordListeningEnabled': instance.keywordListeningEnabled,
      'playbackSpeed': instance.playbackSpeed,
      'recordingQuality': _$AudioQualityEnumMap[instance.recordingQuality]!,
      'backgroundModeEnabled': instance.backgroundModeEnabled,
    };

const _$AudioQualityEnumMap = {
  AudioQuality.low: 'low',
  AudioQuality.medium: 'medium',
  AudioQuality.high: 'high',
};
