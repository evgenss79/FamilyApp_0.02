class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    this.title,
    this.avatarUrl,
    this.lastMessagePreview,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final String? title;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'avatarUrl': avatarUrl,
        'lastMessagePreview': lastMessagePreview,
      };

  Map<String, dynamic> toMetadataMap() => <String, dynamic>{
        'participantIds': participantIds,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Conversation fromDecodableMap(
    Map<String, dynamic> openData, {
    required String id,
    required List<String> participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Conversation(
      id: id,
      participantIds: participantIds,
      title: openData['title'] as String?,
      avatarUrl: openData['avatarUrl'] as String?,
      lastMessagePreview: openData['lastMessagePreview'] as String?,
      createdAt: createdAt ?? parseDate(openData['createdAt']),
      updatedAt: updatedAt ?? parseDate(openData['updatedAt']),
    );
  }

  Conversation copyWith({
    List<String>? participantIds,
    String? title,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
