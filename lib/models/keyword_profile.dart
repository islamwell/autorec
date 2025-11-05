import 'package:json_annotation/json_annotation.dart';

part 'keyword_profile.g.dart';

/// Data model representing a trained keyword profile for voice recognition
@JsonSerializable()
class KeywordProfile {
  /// Unique identifier for the keyword profile
  final String id;
  
  /// The actual keyword text
  final String keyword;
  
  /// File path to the trained model or audio sample
  final String modelPath;
  
  /// Timestamp when the keyword was trained
  final DateTime trainedAt;
  
  /// Confidence threshold for keyword detection (0.0 to 1.0)
  final double confidence;

  const KeywordProfile({
    required this.id,
    required this.keyword,
    required this.modelPath,
    required this.trainedAt,
    required this.confidence,
  });

  /// Creates KeywordProfile from JSON
  factory KeywordProfile.fromJson(Map<String, dynamic> json) => _$KeywordProfileFromJson(json);

  /// Converts KeywordProfile to JSON
  Map<String, dynamic> toJson() => _$KeywordProfileToJson(this);

  /// Validation method to ensure keyword profile data is valid
  bool isValid() {
    if (id.isEmpty) return false;
    if (keyword.isEmpty) return false;
    if (modelPath.isEmpty) return false;
    
    // Confidence should be between 0.0 and 1.0
    if (confidence < 0.0 || confidence > 1.0) return false;
    
    // Keyword should be reasonable length (1-50 characters)
    if (keyword.isEmpty || keyword.length > 50) return false;
    
    return true;
  }

  /// Creates a copy of this keyword profile with updated fields
  KeywordProfile copyWith({
    String? id,
    String? keyword,
    String? modelPath,
    DateTime? trainedAt,
    double? confidence,
  }) {
    return KeywordProfile(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      modelPath: modelPath ?? this.modelPath,
      trainedAt: trainedAt ?? this.trainedAt,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Updates the confidence level for this keyword profile
  KeywordProfile updateConfidence(double newConfidence) {
    if (newConfidence < 0.0 || newConfidence > 1.0) {
      throw ArgumentError('Confidence must be between 0.0 and 1.0');
    }
    return copyWith(confidence: newConfidence);
  }

  /// Checks if the keyword profile is considered reliable based on confidence
  bool get isReliable => confidence >= 0.7;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeywordProfile &&
        other.id == id &&
        other.keyword == keyword &&
        other.modelPath == modelPath &&
        other.trainedAt == trainedAt &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      keyword,
      modelPath,
      trainedAt,
      confidence,
    );
  }

  @override
  String toString() {
    return 'KeywordProfile(id: $id, keyword: $keyword, modelPath: $modelPath, '
        'trainedAt: $trainedAt, confidence: $confidence)';
  }
}