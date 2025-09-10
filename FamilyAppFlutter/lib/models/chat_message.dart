import 'package:hive/hive.dart';

part 'chat_message.g.dart'; // placeholder for code generation

@HiveType(typeId: 21)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
}

@HiveType(typeId: 20)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String chatId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  MessageType type;

  @HiveField(6)
  bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
  });
}

// Manual adapter for ChatMessage
class ChatMessageAdapterManual extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 20;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,      chatId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      type: fields[5] as MessageType,
      isRead: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.isRead);
  }
}


class MessageTypeAdapterManual extends TypeAdapter<MessageType> {
  @override
  final int typeId = 21;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.image;
      case 2:
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
        break;
      case MessageType.image:
        writer.writeByte(1);
        break;
      case MessageType.file:
        writer.writeByte(2);
        break;
    }
  }
}
