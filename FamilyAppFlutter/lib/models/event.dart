class Event {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    List<String>? participantIds,
    DateTime? updatedAt,
  })  : participantIds = participantIds ?? const [],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'description': description,
        'participantIds': participantIds,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Event fromMap(Map<String, dynamic> m) {
    final start = m['startDateTime'] is String ? DateTime.tryParse(m['startDateTime']) : null;
    final end = m['endDateTime'] is String ? DateTime.tryParse(m['endDateTime']) : null;
    return Event(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      startDateTime: start ?? DateTime.now(),
      endDateTime: end ?? (start ?? DateTime.now()),
      description: m['description'] as String?,
      participantIds: (m['participantIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      updatedAt: m['updatedAt'] is String ? DateTime.tryParse(m['updatedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
