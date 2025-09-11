import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 21)
enum MessageType {
  @HiveField(0) text,
  @HiveField(1) image,
  @HiveField(2) file,
}

@HiveType(typeId: 20)
class ChatMessage extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String chatId;
  @HiveField(2) String senderId;
  @HiveField(3) String content;
  @HiveField(4) DateTime createdAt;
  @HiveField(5) MessageType type;
  @HiveField(6) bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        chatId: m['chatId'] as String,
        senderId: m['senderId'] as String,
        content: m['content'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        type: MessageType.values[(m['type'] as int?) ?? 0],
        isRead: (m['isRead'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'type': type.index,
        'isRead': isRead,
      };
}
