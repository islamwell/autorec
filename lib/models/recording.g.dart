// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recording _$RecordingFromJson(Map<String, dynamic> json) => Recording(
  id: json['id'] as String,
  filePath: json['filePath'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  keyword: json['keyword'] as String?,
  fileSize: (json['fileSize'] as num).toDouble(),
  quality: $enumDecode(_$RecordingQualityEnumMap, json['quality']),
);

Map<String, dynamic> _$RecordingToJson(Recording instance) => <String, dynamic>{
  'id': instance.id,
  'filePath': instance.filePath,
  'createdAt': instance.createdAt.toIso8601String(),
  'duration': instance.duration.inMicroseconds,
  'keyword': instance.keyword,
  'fileSize': instance.fileSize,
  'quality': _$RecordingQualityEnumMap[instance.quality]!,
};

const _$RecordingQualityEnumMap = {
  RecordingQuality.low: 'low',
  RecordingQuality.medium: 'medium',
  RecordingQuality.high: 'high',
};
