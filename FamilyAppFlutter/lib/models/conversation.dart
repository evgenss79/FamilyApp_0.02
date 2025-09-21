class Conversation {
  final String id;
  final String title;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? lastMessageTime;

  Conversation({
    required this.id,
    required this.title,
    required this.memberIds,
    this.createdAt,
    this.lastMessageTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'memberIds': memberIds,
        'createdAt': createdAt?.toIso8601String(),
        'lastMessageTime': lastMessageTime?.toIso8601String(),
      };

  static Conversation fromMap(Map<String, dynamic> m) => Conversation(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        memberIds: (m['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        createdAt: m['createdAt'] is String ? DateTime.tryParse(m['createdAt']) : null,
        lastMessageTime: m['lastMessageTime'] is String ? DateTime.tryParse(m['lastMessageTime']) : null,
      );
}
