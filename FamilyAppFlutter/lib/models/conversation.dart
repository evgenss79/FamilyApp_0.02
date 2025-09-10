import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 4)
class Conversation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final List<String> memberIds;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime? lastMessageTime;

  Conversation({
    String? id,
    required this.title,
    required this.memberIds,
    DateTime? createdAt,
    this.lastMessageTime,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }

  static Conversation fromMap(Map<String, dynamic> map) {
    final membersDynamic = map['memberIds'] as List<dynamic>?;
    final memberIds = membersDynamic?.cast<String>() ?? <String>[];
    return Conversation(
      id: map['id'] as String?,
      title: map['title'] as String,
      memberIds: memberIds,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      lastMessageTime: map['lastMessageTime'] != null ? DateTime.parse(map['lastMessageTime']) : null,
    );
  }
}

class ConversationAdapterManual extends TypeAdapter<Conversation> {
  @override
  final int typeId = 4;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String?,
      title: fields[1] as String,
      memberIds: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
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
