import 'package:flutter/foundation.dart';

/// Model for a scheduled recording
class ScheduledRecording {
  final String id;
  final String name;
  final TimeOfDay time;
  final Duration duration;
  final bool isEnabled;
  final DateTime createdAt;

  const ScheduledRecording({
    required this.id,
    required this.name,
    required this.time,
    required this.duration,
    this.isEnabled = true,
    required this.createdAt,
  });

  ScheduledRecording copyWith({
    String? id,
    String? name,
    TimeOfDay? time,
    Duration? duration,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ScheduledRecording(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'durationMinutes': duration.inMinutes,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduledRecording.fromJson(Map<String, dynamic> json) {
    return ScheduledRecording(
      id: json['id'] as String,
      name: json['name'] as String,
      time: TimeOfDay(
        hour: json['timeHour'] as int,
        minute: json['timeMinute'] as int,
      ),
      duration: Duration(minutes: json['durationMinutes'] as int),
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get formattedTime {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get formattedDuration {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hr';
      }
      return '$hours hr $minutes min';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledRecording &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// TimeOfDay helper for JSON serialization
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
