class ScheduleItem {
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
    DateTime _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    Duration? _parseDuration(dynamic value) {
      if (value is int) return Duration(minutes: value);
      if (value is String && value.isNotEmpty) {
        final int? minutes = int.tryParse(value);
        return minutes != null ? Duration(minutes: minutes) : null;
      }
      return null;
    }

    DateTime? _parseNullable(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ScheduleItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      dateTime: _parseDate(map['dateTime']),
      duration: _parseDuration(map['duration']),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      memberId: map['memberId'] as String?,
      createdAt: _parseNullable(map['createdAt']),
      updatedAt: _parseNullable(map['updatedAt']),
    );
  }
}
