// GENERATED CODE - MANUALLY CREATED

// This file provides a Hive TypeAdapter for the Chat model.
// Normally, this code is generated automatically by build_runner, but it
// has been manually implemented here to satisfy the dependency without
// requiring code generation.  Do not modify unless you know what you are doing.

part of 'chat.dart';

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 11;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return Chat(
      id: fields[0] as String,
      title: fields[1] as String,
      memberIds: (fields[2] as List).cast(),
      updatedAt: fields[3] as DateTime,
      lastMessagePreview: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.memberIds)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.lastMessagePreview);
  }
}