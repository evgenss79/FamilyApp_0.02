import 'package:family_app_flutter/utils/parsing.dart';

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


  final String id;
  final List<String> participantIds;
  final String? title;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get memberIds => participantIds;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'memberIds': memberIds,
        'createdAt': createdAt?.toIso8601String(),
        'lastMessageTime': lastMessageTime?.toIso8601String(),
      };

  static Conversation fromDecodableMap(
    Map<String, dynamic> openData, {
    required String id,
    required List<String> participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {

    return Conversation(
      id: id,
      participantIds: participantIds,
      title: openData['title'] as String?,
      avatarUrl: openData['avatarUrl'] as String?,
      lastMessagePreview: openData['lastMessagePreview'] as String?,
      createdAt: createdAt ?? parseNullableDateTime(openData['createdAt']),
      updatedAt: updatedAt ?? parseNullableDateTime(openData['updatedAt']),

    );
  }

  Conversation copyWith({
    List<String>? participantIds,
    String? title,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

}
