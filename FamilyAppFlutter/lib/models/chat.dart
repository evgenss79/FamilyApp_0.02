import 'package:hive/hive.dart';

part 'chat.g.dart';

/// A conversation between two or more family members.  Chats hold
/// metadata such as the title, participating member identifiers, last
/// updated timestamp and a preview of the most recent message.  The
/// contents of the messages themselves are stored separately.
@HiveType(typeId: 11)
class Chat extends HiveObject {
  /// Unique identifier for this chat.
  @HiveField(0)
  String id;

  /// User-provided title of the chat (e.g. "Family group").
  @HiveField(1)
  String title;

  /// List of member identifiers participating in this chat.
  @HiveField(2)
  List<dynamic> memberIds;

  /// Timestamp of the last activity in this chat.
  @HiveField(3)
  DateTime updatedAt;

  /// Optional preview of the most recent message sent in this chat.
  @HiveField(4)
  String? lastMessagePreview;

  Chat({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.updatedAt,
    this.lastMessagePreview,
  });
}