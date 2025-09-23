import '../utils/parsing.dart';

/// Item in the weekly schedule such as school or extracurricular activity.
class ScheduleItem {
  static const Object _sentinel = Object();

  const ScheduleItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.duration,
    this.location,
    this.notes,
    this.memberId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final Duration? duration;
  final String? location;
  final String? notes;
  final String? memberId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime get endDateTime =>
      duration == null ? dateTime : dateTime.add(duration!);

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'duration': duration?.inMinutes,
        'location': location,
        'notes': notes,
        'memberId': memberId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  ScheduleItem copyWith({
    Object? title = _sentinel,
    Object? dateTime = _sentinel,
    Object? duration = _sentinel,
    Object? location = _sentinel,
    Object? notes = _sentinel,
    Object? memberId = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return ScheduleItem(
      id: id,
      title: title == _sentinel ? this.title : title as String,
      dateTime: dateTime == _sentinel ? this.dateTime : dateTime as DateTime,
      duration:
          duration == _sentinel ? this.duration : duration as Duration?,
      location: location == _sentinel ? this.location : location as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      memberId: memberId == _sentinel ? this.memberId : memberId as String?,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
