class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  static Message fromMap(Map<String, dynamic> m) => Message(
        id: (m['id'] ?? '').toString(),
        conversationId: (m['conversationId'] ?? '').toString(),
        senderId: (m['senderId'] ?? '').toString(),
        content: (m['content'] ?? '').toString(),
        timestamp: m['timestamp'] is String
            ? DateTime.tryParse(m['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}
