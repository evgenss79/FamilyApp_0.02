import 'package:hive/hive.dart';

part 'message.g.dart';

/// Represents a message within a conversation.  This model is similar
/// to [ChatMessage] but is used for conversations rather than chats.
@HiveType(typeId: 5)
class Message extends HiveObject {
  /// Unique identifier for the message.  May be null for newly
  /// constructed messages before they are saved.
  @HiveField(0)
  String? id;

  /// Identifier of the conversation this message belongs to.
  @HiveField(1)
  String conversationId;

  /// Identifier of the member who sent the message.
  @HiveField(2)
  String senderId;

  /// Message content.
  @HiveField(3)
  String content;

  /// When the message was sent.
  @HiveField(4)
  DateTime timestamp;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });
}