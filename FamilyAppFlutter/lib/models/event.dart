class Event {
  const Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    this.participantIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'description': description,
        'participantIds': participantIds,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Event fromDecodableMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((dynamic e) => e.toString()).toList();
      }
      return const <String>[];
    }

    DateTime? parseNullable(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Event(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      startDateTime: parseDate(map['startDateTime']),
      endDateTime: parseDate(map['endDateTime']),
      description: map['description'] as String?,
      participantIds: parseList(map['participantIds']),
      createdAt: parseNullable(map['createdAt']),
      updatedAt: parseNullable(map['updatedAt']),
    );
  }
}
