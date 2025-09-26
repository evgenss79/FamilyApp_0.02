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
    this.status,
    this.type,
    this.createdBy,
    this.endedAt,
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

  /// Lifecycle status of the conversation (e.g. ringing, connected, ended).
  final String? status;

  /// Distinguishes audio vs. video calls for call conversations.
  final String? type;

  /// Identifier of the member who created the conversation/call.
  final String? createdBy;

  /// When the call ended if it has completed.
  final DateTime? endedAt;

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
      status: map['status'] as String?,
      type: map['type'] as String?,
      createdBy: map['createdBy'] as String?,
      endedAt: parseNullableDateTime(map['endedAt']),
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
        'status': status,
        'type': type,
        'createdBy': createdBy,
        'endedAt': endedAt?.toIso8601String(),
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
    String? status,
    String? type,
    String? createdBy,
    DateTime? endedAt,
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
      status: status ?? this.status,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
