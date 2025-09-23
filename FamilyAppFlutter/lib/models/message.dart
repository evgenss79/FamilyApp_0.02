import 'package:family_app_flutter/utils/parsing.dart';

enum MessageType { text, image, file }

enum MessageStatus { sending, sent, delivered, read }

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.ciphertext,
    required this.iv,
    required this.encVersion,
    required this.createdAt,
    this.editedAt,
    this.status = MessageStatus.sent,
    this.openData = const <String, dynamic>{},
  });

  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String ciphertext;
  final String iv;
  final int encVersion;
  final DateTime createdAt;
  final DateTime? editedAt;
  final MessageStatus status;
  final Map<String, dynamic> openData;

  String? get text => openData['text'] as String?;
  Map<String, dynamic>? get attachments =>
      openData['attachments'] as Map<String, dynamic>?;

  Map<String, dynamic> toEncodableMap() => openData;

  Map<String, dynamic> toMetadataMap() => <String, dynamic>{
        'senderId': senderId,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': type.name,
        'ciphertext': ciphertext,
        'iv': iv,
        'encVersion': encVersion,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'status': status.name,
        'openData': openData,
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
    MessageType parseType(dynamic value) {
      final String name = value?.toString() ?? 'text';
      return MessageType.values.firstWhere(
        (MessageType type) => type.name == name,
        orElse: () => MessageType.text,
      );
    }

    MessageStatus parseStatus(dynamic value) {
      final String name = value?.toString() ?? 'sent';
      return MessageStatus.values.firstWhere(
        (MessageStatus status) => status.name == name,
        orElse: () => MessageStatus.sent,
      );
    }

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
      type: parseType(metadata['type']),
      ciphertext: ciphertext,
      iv: iv,
      encVersion: encVersion,
      createdAt: createdAt,
      editedAt: parseNullableDateTime(metadata['editedAt']),
      status: parseStatus(metadata['status']),
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
