// GENERATED CODE - MANUALLY CREATED

// This file defines a Hive TypeAdapter for the Conversation model.
// It mirrors the behavior of the code normally produced by build_runner.

part of 'conversation.dart';

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 12;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return Conversation(
      id: fields[0] as String,
      title: fields[1] as String,
      memberIds: (fields[2] as List).cast(),
      createdAt: fields[3] as DateTime?,
      lastMessageTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.memberIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastMessageTime);
  }
}