class ScheduleItem {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String? description;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.startDateTime,
    this.endDateTime,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime?.toIso8601String(),
        'description': description,
      };

  static ScheduleItem fromMap(Map<String, dynamic> m) => ScheduleItem(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        startDateTime: m['startDateTime'] is String ? DateTime.parse(m['startDateTime']) : DateTime.now(),
        endDateTime: m['endDateTime'] is String ? DateTime.tryParse(m['endDateTime']) : null,
        description: m['description'] as String?,
      );
}
class ScheduleItem {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String? description;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.startDateTime,
    this.endDateTime,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime?.toIso8601String(),
        'description': description,
      };

  static ScheduleItem fromMap(Map<String, dynamic> m) => ScheduleItem(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        startDateTime: m['startDateTime'] is String ? DateTime.parse(m['startDateTime']) : DateTime.now(),
        endDateTime: m['endDateTime'] is String ? DateTime.tryParse(m['endDateTime']) : null,
        description: m['description'] as String?,
      );
}
