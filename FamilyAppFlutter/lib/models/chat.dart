import '../utils/parsing.dart';
import 'package:hive/hive.dart';

part 'chat.g.dart';

/// A conversation between two or more family members stored locally for quick
/// access. The encrypted payload lives in Firestore, while this model keeps
/// metadata such as the title and last message preview.
@HiveType(typeId: 11)
class Chat {
  Chat({
    required this.id,
    required this.title,
    required List<String> memberIds,
    required this.updatedAt,
    this.lastMessagePreview,
  }) : memberIds = List.unmodifiable(memberIds);

  /// Unique identifier for this chat.
  @HiveField(0)
  final String id;

  /// Human friendly title for the chat.
  @HiveField(1)
  final String title;

  /// Participants of the chat.
  @HiveField(2)
  final List<String> memberIds;

  /// Timestamp of the most recent message or metadata change.
  @HiveField(3)
  final DateTime updatedAt;

  /// Optional preview text for the last message.
  @HiveField(4)
  final String? lastMessagePreview;

  factory Chat.fromMap(Map<String, dynamic> map) => Chat(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        memberIds: (map['memberIds'] as List?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
        updatedAt: parseDateTimeOrNow(map['updatedAt']),
        lastMessagePreview: map['lastMessagePreview'] as String?,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'memberIds': memberIds,
        'updatedAt': updatedAt.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
      };

  Chat copyWith({
    String? title,
    List<String>? memberIds,
    DateTime? updatedAt,
    String? lastMessagePreview,
  }) {
    return Chat(
      id: id,
      title: title ?? this.title,
      memberIds: memberIds ?? this.memberIds,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
