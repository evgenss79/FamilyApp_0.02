import 'message_type.dart';
import '../utils/parsing.dart';

/// Delivery status of a message stored in Firestore.
enum MessageStatus { sending, sent, delivered, read }

/// Generic message model used by encrypted call conversations.
class Message {
  static const Object _sentinel = Object();

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final MessageStatus status;

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: (map['id'] ?? '').toString(),
      conversationId: (map['conversationId'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      type: _parseType(map['type']) ?? MessageType.text,
      content: (map['content'] ?? '').toString(),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      editedAt: parseNullableDateTime(map['editedAt']),
      status: _parseStatus(map['status']) ?? MessageStatus.sent,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': type.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'status': status.name,
      };

  Message copyWith({
    Object? type = _sentinel,
    Object? content = _sentinel,
    Object? createdAt = _sentinel,
    Object? editedAt = _sentinel,
    Object? status = _sentinel,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      type: type == _sentinel ? this.type : type as MessageType,
      content: content == _sentinel ? this.content : content as String,
      createdAt: createdAt == _sentinel
          ? this.createdAt
          : createdAt as DateTime,
      editedAt:
          editedAt == _sentinel ? this.editedAt : editedAt as DateTime?,
      status: status == _sentinel ? this.status : status as MessageStatus,
    );
  }

  static MessageType? _parseType(dynamic value) {
    if (value is MessageType) {
      return value;
    }
    final String? name = value?.toString();
    if (name == null || name.isEmpty) {
      return null;
    }
    for (final MessageType type in MessageType.values) {
      if (type.name.toLowerCase() == name.toLowerCase()) {
        return type;
      }
    }
    return null;
  }

  static MessageStatus? _parseStatus(dynamic value) {
    if (value is MessageStatus) {
      return value;
    }
    final String? name = value?.toString();
    if (name == null || name.isEmpty) {
      return null;
    }
    for (final MessageStatus status in MessageStatus.values) {
      if (status.name.toLowerCase() == name.toLowerCase()) {
        return status;
      }
    }
    return null;
  }
}
