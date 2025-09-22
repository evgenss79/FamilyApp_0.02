// GENERATED CODE - MANUALLY CREATED

// This file provides Hive TypeAdapters for the MessageType enum and
// ChatMessage class.  Normally these adapters are generated, but they
// have been implemented manually to remove the dependency on code
// generation tools.  Do not modify unless you understand the
// consequences.

part of 'chat_message.dart';

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 21;

  @override
  MessageType read(BinaryReader reader) {
    final byte = reader.readByte();
    switch (byte) {
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
    writer.writeByte(obj.index);
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 20;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return ChatMessage(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      type: fields[5] as MessageType,
      isRead: fields[6] as bool,
      storagePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.storagePath);
  }
}