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

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as String,
      title: map['title'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      duration:
          map['duration'] != null ? Duration(minutes: map['duration']) : null,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      memberId: map['memberId'] as String?,
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
