import 'package:hive/hive.dart';

part 'chat.g.dart'; // placeholder for code generation

@HiveType(typeId: 11)
class Chat extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<String> memberIds;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String? lastMessagePreview;

  Chat({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.updatedAt,
    this.lastMessagePreview,
  });
}

// Manual adapter for Chat
////class ChatAdapter extends TypeAdapter<Chat> {
//  @override
//  final int typeId = 11;
//
//  @override
//  Chat read(BinaryReader reader) {
//    final numOfFields = reader.readByte();
//    final fields = <int, dynamic>{
//      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//    };
//    return Chat(
//      id: fields[0] as String,
//      title: fields[1] as String,
//      memberIds: (fields[2] as List).cast<String>(),
//      updatedAt: fields[3] as DateTime,
//      lastMessagePreview: fields[4] as String?,
//    );
/  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(5)
//      ..writeByte(0)
//      ..write(obj.id)
//      ..writeByte(1)
//      ..write(obj.title)
//      ..writeByte(2)
//      ..write(obj.memberIds)
//      ..writeByte(3)
//      ..write(obj.updatedAt)
//      ..writeByte(4)
//      ..write(obj.lastMessagePreview);
//  }
//}
//
