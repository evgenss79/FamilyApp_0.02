import 'package:hive/hive.dart';

part 'conversation.g.dart';

/// Represents a high-level conversation between family members.  A
/// conversation holds participant information and time metadata, but
/// individual messages are stored separately.
@HiveType(typeId: 12)
class Conversation extends HiveObject {
  /// Unique identifier for the conversation.
  @HiveField(0)
  String id;

  /// Title or subject of the conversation.
  @HiveField(1)
  String title;

  /// List of member identifiers participating in the conversation.
  @HiveField(2)
  List<dynamic> memberIds;

  /// When the conversation was created.
  @HiveField(3)
  DateTime? createdAt;

  /// Time of the most recent message in the conversation.
  @HiveField(4)
  DateTime? lastMessageTime;

  Conversation({
    required this.id,
    required this.title,
    required this.memberIds,
    this.createdAt,
    this.lastMessageTime,
  });
}