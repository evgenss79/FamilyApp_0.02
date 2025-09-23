import 'package:family_app_flutter/utils/parsing.dart';

enum MessageType { text, image, file }

enum MessageStatus { sending, sent, delivered, read }

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

  static Message fromDecodableMap(
    Map<String, dynamic> openData, {
    required Map<String, dynamic> metadata,
    required String id,
    required String conversationId,
    required String ciphertext,
    required String iv,
    required int encVersion,
  }) {

    DateTime createdAt = parseDateTimeOrNow(metadata['createdAt']);
    final DateTime? legacyCreated =
        parseNullableDateTime(openData['createdAtLocal']);
    if (legacyCreated != null) {
      createdAt = legacyCreated;
    }
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: metadata['senderId']?.toString() ?? '',
      type: _parseType(metadata['type']),
      ciphertext: ciphertext,
      iv: iv,
      encVersion: encVersion,
      createdAt: createdAt,
      editedAt: parseNullableDateTime(metadata['editedAt']),
      status: _parseStatus(metadata['status']),
      openData: openData,
    );
  }

  static Message fromCache(Map<String, dynamic> map) {
    return Message.fromDecodableMap(
      Map<String, dynamic>.from(map['openData'] as Map? ?? <String, dynamic>{}),
      metadata: <String, dynamic>{
        'senderId': map['senderId'],
        'type': map['type'],
        'status': map['status'],
        'createdAt': map['createdAt'],
        'editedAt': map['editedAt'],
      },
      id: (map['id'] ?? '').toString(),
      conversationId: (map['conversationId'] ?? '').toString(),
      ciphertext: (map['ciphertext'] ?? '').toString(),
      iv: (map['iv'] ?? '').toString(),
      encVersion: map['encVersion'] is int
          ? map['encVersion'] as int
          : int.tryParse('${map['encVersion']}') ?? 0,
    );
  }

  static MessageType _parseType(dynamic value) {
    if (value is MessageType) {
      return value;
    }
    final String? rawName = value?.toString();
    if (rawName != null && rawName.isNotEmpty) {
      final String normalized = rawName.contains('.')
          ? rawName.substring(rawName.lastIndexOf('.') + 1)
          : rawName;
      final String lowerNormalized = normalized.toLowerCase();
      for (final MessageType type in MessageType.values) {
        if (type.name.toLowerCase() == lowerNormalized) {
          return type;
        }
      }
    }
    return MessageType.text;
  }

  static MessageStatus _parseStatus(dynamic value) {
    if (value is MessageStatus) {
      return value;
    }
    final String? rawName = value?.toString();
    if (rawName != null && rawName.isNotEmpty) {
      final String normalized = rawName.contains('.')
          ? rawName.substring(rawName.lastIndexOf('.') + 1)
          : rawName;
      final String lowerNormalized = normalized.toLowerCase();
      for (final MessageStatus status in MessageStatus.values) {
        if (status.name.toLowerCase() == lowerNormalized) {
          return status;
        }
      }
    }
    return MessageStatus.sent;
  }

  Message copyWith({
    MessageType? type,
    String? ciphertext,
    String? iv,
    int? encVersion,
    DateTime? createdAt,
    DateTime? editedAt,
    MessageStatus? status,
    Map<String, dynamic>? openData,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      type: type ?? this.type,
      ciphertext: ciphertext ?? this.ciphertext,
      iv: iv ?? this.iv,
      encVersion: encVersion ?? this.encVersion,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      openData: openData ?? this.openData,
    );
  }
}
