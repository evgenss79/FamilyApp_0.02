import '../utils/parsing.dart';

/// Represents a realtime call or chat conversation between family members.
/// The model keeps only high level metadata while the encrypted payload of
/// individual messages is stored separately in Firestore.
class Conversation {
  Conversation({
    required this.id,
    required this.title,
    required List<String> participantIds,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageTime,
    this.avatarUrl,
    this.lastMessagePreview,
  }) : participantIds = List.unmodifiable(participantIds);

  /// Unique identifier of the conversation document in Firestore.
  final String id;

  /// Human friendly title that is shown to the users.
  final String title;

  /// Identifiers of members participating in this conversation.
  final List<String> participantIds;

  /// When the conversation was created.
  final DateTime createdAt;

  /// Timestamp of the last update (e.g. message sent or metadata change).
  final DateTime? updatedAt;

  /// Timestamp of the latest message if available.
  final DateTime? lastMessageTime;

  /// Optional URL of the conversation avatar.
  final String? avatarUrl;

  /// Preview text of the last message used in lists.
  final String? lastMessagePreview;

  /// Creates a [Conversation] from a Firestore map. Non existing optional
  /// fields gracefully fall back to sensible defaults.
  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      participantIds: parseStringList(map['participantIds']),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
      lastMessageTime: parseNullableDateTime(map['lastMessageTime']),
      avatarUrl: map['avatarUrl'] as String?,
      lastMessagePreview: map['lastMessagePreview'] as String?,
    );
  }

  /// Serialises the conversation to a JSON compatible map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'participantIds': participantIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'lastMessageTime': lastMessageTime?.toIso8601String(),
        'avatarUrl': avatarUrl,
        'lastMessagePreview': lastMessagePreview,
      };

  /// Returns a copy of this conversation with the provided fields replaced.
  Conversation copyWith({
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageTime,
    String? avatarUrl,
    String? lastMessagePreview,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
