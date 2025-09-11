import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 12)
class Conversation extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) List<String> memberIds;
  @HiveField(3) DateTime? createdAt;
  @HiveField(4) DateTime? lastMessageTime;

  Conversation({
    required this.id,
    required this.title,
    required this.memberIds,
    this.createdAt,
    this.lastMessageTime,
  });

  factory Conversation.fromMap(Map<String, dynamic> m) => Conversation(
        id: m['id'] as String,
        title: m['title'] as String,
        memberIds: (m['memberIds'] as List).cast<String>(),
        createdAt: (m['createdAt'] as String?) != null
            ? DateTime.parse(m['createdAt'] as String)
            : null,
        lastMessageTime: (m['lastMessageTime'] as String?) != null
            ? DateTime.parse(m['lastMessageTime'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'memberIds': memberIds,
        'createdAt': createdAt?.toIso8601String(),
        'lastMessageTime': lastMessageTime?.toIso8601String(),
      };
}
