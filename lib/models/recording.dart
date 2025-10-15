import 'package:json_annotation/json_annotation.dart';

part 'recording.g.dart';

/// Enum representing different recording quality levels
enum RecordingQuality {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

/// Data model representing a voice recording
@JsonSerializable()
class Recording {
  /// Unique identifier for the recording
  final String id;
  
  /// File path where the recording is stored
  final String filePath;
  
  /// Timestamp when the recording was created
  final DateTime createdAt;
  
  /// Duration of the recording
  final Duration duration;
  
  /// Keyword that triggered this recording (if any)
  final String? keyword;
  
  /// File size in bytes
  final double fileSize;
  
  /// Quality level of the recording
  final RecordingQuality quality;

  const Recording({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.duration,
    this.keyword,
    required this.fileSize,
    required this.quality,
  });

  /// Creates a Recording from JSON
  factory Recording.fromJson(Map<String, dynamic> json) => _$RecordingFromJson(json);

  /// Converts Recording to JSON
  Map<String, dynamic> toJson() => _$RecordingToJson(this);

  /// Validation method to ensure recording data is valid
  bool isValid() {
    if (id.isEmpty) return false;
    if (filePath.isEmpty) return false;
    if (fileSize < 0) return false;
    if (duration.inMilliseconds <= 0) return false;
    return true;
  }

  /// Creates a copy of this recording with updated fields
  Recording copyWith({
    String? id,
    String? filePath,
    DateTime? createdAt,
    Duration? duration,
    String? keyword,
    double? fileSize,
    RecordingQuality? quality,
  }) {
    return Recording(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      keyword: keyword ?? this.keyword,
      fileSize: fileSize ?? this.fileSize,
      quality: quality ?? this.quality,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recording &&
        other.id == id &&
        other.filePath == filePath &&
        other.createdAt == createdAt &&
        other.duration == duration &&
        other.keyword == keyword &&
        other.fileSize == fileSize &&
        other.quality == quality;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      filePath,
      createdAt,
      duration,
      keyword,
      fileSize,
      quality,
    );
  }

  @override
  String toString() {
    return 'Recording(id: $id, filePath: $filePath, createdAt: $createdAt, '
        'duration: $duration, keyword: $keyword, fileSize: $fileSize, quality: $quality)';
  }
}