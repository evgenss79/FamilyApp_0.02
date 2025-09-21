import 'package:hive/hive.dart';

part 'chat_message.g.dart';

/// Types of messages that can be sent in a chat.  Text messages
/// contain plain text, image messages reference a local file path, and
/// file messages reference any other kind of file path.
@HiveType(typeId: 21)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
}

/// Represents an individual message within a chat.  A message has an
/// associated sender, belongs to a particular chat, and may be
/// marked as read.  Attachments are stored as the content for
/// non‑text messages.
@HiveType(typeId: 20)
class ChatMessage extends HiveObject {
  /// Unique identifier for this message.
  @HiveField(0)
  String id;

  /// Identifier of the chat this message belongs to.
  @HiveField(1)
  String chatId;

  /// Identifier of the member who sent the message.
  @HiveField(2)
  String senderId;

  /// The message text or file path, depending on the type.
  @HiveField(3)
  String content;

  /// When the message was created.
  @HiveField(4)
  DateTime createdAt;

  /// The type of message (text, image, or file).
  @HiveField(5)
  MessageType type;

  /// Whether the message has been read by the recipient.
  @HiveField(6)
  bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.isRead,
  });
}