class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? endDateTime;
  final String? assignedMemberId;
  final String status; // 'Pending' | 'In Progress' | 'Completed'
  final int points;
  final List<DateTime> reminders;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.endDateTime,
    this.assignedMemberId,
    this.status = 'Pending',
    this.points = 0,
    List<DateTime>? reminders,
    this.latitude,
    this.longitude,
    this.locationName,
  }) : reminders = reminders ?? const [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'endDateTime': endDateTime?.toIso8601String(),
        'assignedMemberId': assignedMemberId,
        'status': status,
        'points': points,
        'reminders': reminders.map((e) => e.toIso8601String()).toList(),
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
      };

  static Task fromMap(Map<String, dynamic> m) => Task(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        description: m['description'] as String?,
        endDateTime: m['endDateTime'] is String ? DateTime.tryParse(m['endDateTime']) : null,
        assignedMemberId: m['assignedMemberId'] as String?,
        status: (m['status'] ?? 'Pending').toString(),
        points: m['points'] is int ? m['points'] as int : int.tryParse('${m['points']}') ?? 0,
        reminders: (m['reminders'] as List?)
                ?.map((e) => e is String ? DateTime.tryParse(e) : null)
                .whereType<DateTime>()
                .toList() ??
            const [],
        latitude: m['latitude'] is num ? (m['latitude'] as num).toDouble() : null,
        longitude: m['longitude'] is num ? (m['longitude'] as num).toDouble() : null,
        locationName: m['locationName'] as String?,
      );
}
