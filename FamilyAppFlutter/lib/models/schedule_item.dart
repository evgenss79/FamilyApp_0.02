import 'package:family_app_flutter/utils/parsing.dart';

class ScheduleItem {
  final String id;
  final String title;
  final DateTime dateTime;
  final Duration? duration;
  final String? location;
  final String? notes;
  final String? memberId;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.duration,
    this.location,
    this.notes,
    this.memberId,
  });

  DateTime get endDateTime =>
      duration == null ? dateTime : dateTime.add(duration!);

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'duration': duration?.inMinutes,
        'location': location,
        'notes': notes,
        'memberId': memberId,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static ScheduleItem fromDecodableMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      dateTime: parseDateTimeOrNow(map['dateTime']),
      duration: parseDurationFromMinutes(map['duration']),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      memberId: map['memberId'] as String?,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration?.inMinutes,
      'location': location,
      'notes': notes,
      'memberId': memberId,
    };
  }
}
