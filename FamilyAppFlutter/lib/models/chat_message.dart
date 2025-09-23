import 'message_type.dart';
import '../utils/parsing.dart';
import 'package:hive/hive.dart';

part 'chat_message.g.dart';

/// Represents an individual message within a chat. Attachments are stored as
/// URLs in [content] while metadata is encrypted remotely.
@HiveType(typeId: 20)
class ChatMessage {
  static const Object _sentinel = Object();

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.isRead,
    this.storagePath,
  });

  /// Unique identifier for this message.
  @HiveField(0)
  final String id;

  /// Identifier of the chat this message belongs to.
  @HiveField(1)
  final String chatId;

  /// Identifier of the member who sent the message.
  @HiveField(2)
  final String senderId;

  /// The message text or file URL depending on the [type].
  @HiveField(3)
  final String content;

  /// When the message was created.
  @HiveField(4)
  final DateTime createdAt;

  /// The type of message (text, image, or file).
  @HiveField(5)
  final MessageType type;

  /// Whether the message has been read by the recipient.
  @HiveField(6)
  final bool isRead;

  /// Optional storage path of the attachment (if any).
  @HiveField(7)
  final String? storagePath;

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: (map['id'] ?? '').toString(),
        chatId: (map['chatId'] ?? '').toString(),
        senderId: (map['senderId'] ?? '').toString(),
        content: (map['content'] ?? '').toString(),
        createdAt: parseDateTimeOrNow(map['createdAt']),
        type: _messageTypeFromString(map['type']),
        isRead: map['isRead'] is bool
            ? map['isRead'] as bool
            : (map['isRead']?.toString().toLowerCase() == 'true'),
        storagePath: map['storagePath'] as String?,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'isRead': isRead,
        'storagePath': storagePath,
      };

  ChatMessage copyWith({
    Object? content = _sentinel,
    Object? createdAt = _sentinel,
    Object? type = _sentinel,
    Object? isRead = _sentinel,
    Object? storagePath = _sentinel,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content == _sentinel ? this.content : content as String,
      createdAt: createdAt == _sentinel
          ? this.createdAt
          : createdAt as DateTime,
      type: type == _sentinel ? this.type : type as MessageType,
      isRead: isRead == _sentinel ? this.isRead : isRead as bool,
      storagePath:
          storagePath == _sentinel ? this.storagePath : storagePath as String?,
    );
  }

  static MessageType _messageTypeFromString(dynamic value) {
    if (value is MessageType) {
      return value;
    }
    final String? name = value?.toString();
    if (name == null || name.isEmpty) {
      return MessageType.text;
    }
    final String lower = name.toLowerCase();
    for (final MessageType type in MessageType.values) {
      if (type.name.toLowerCase() == lower) {
        return type;
      }
    }
    return MessageType.text;
  }
}
