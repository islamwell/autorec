// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyword_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeywordProfile _$KeywordProfileFromJson(Map<String, dynamic> json) =>
    KeywordProfile(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      modelPath: json['modelPath'] as String,
      trainedAt: DateTime.parse(json['trainedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$KeywordProfileToJson(KeywordProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'keyword': instance.keyword,
      'modelPath': instance.modelPath,
      'trainedAt': instance.trainedAt.toIso8601String(),
      'confidence': instance.confidence,
    };
