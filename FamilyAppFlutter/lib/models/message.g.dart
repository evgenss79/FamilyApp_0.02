// GENERATED CODE - MANUALLY CREATED

// This file defines a Hive TypeAdapter for the Message model.
// Normally generated via build_runner, implemented manually here.

part of 'message.dart';

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 5;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return Message(
      id: fields[0] as String?,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp);
  }
}