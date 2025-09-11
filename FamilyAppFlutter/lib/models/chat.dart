import 'package:hive/hive.dart';

part 'chat.g.dart';

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

  factory Chat.fromMap(Map<String, dynamic> m) => Chat(
        id: m['id'] as String,
        title: m['title'] as String,
        memberIds: (m['memberIds'] as List).cast<String>(),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        lastMessagePreview: m['lastMessagePreview'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'memberIds': memberIds,
        'updatedAt': updatedAt.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
      };
}
