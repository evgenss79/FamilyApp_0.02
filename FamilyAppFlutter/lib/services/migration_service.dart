import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat.dart' as legacy;
import '../models/chat_message.dart' as legacy;
import '../models/conversation.dart';
import '../models/message.dart';
import 'firestore_service.dart';

class MigrationService {
  MigrationService({required FirestoreService firestore})
      : _firestore = firestore;

  final FirestoreService _firestore;

  Future<void> migrateLegacyHiveData(String familyId) async {
    final bool chatsExist = await Hive.boxExists('chats');
    final bool messagesExist = await Hive.boxExists('chat_messages');
    if (!chatsExist || !messagesExist) {
      return;
    }

    _registerAdapters();

    final Box<legacy.Chat> chatsBox = await Hive.openBox<legacy.Chat>('chats');
    final Box<legacy.ChatMessage> messagesBox =
        await Hive.openBox<legacy.ChatMessage>('chat_messages');

    for (final legacy.Chat chat in chatsBox.values) {
      final Conversation conversation = Conversation(
        id: chat.id,
        participantIds: chat.memberIds,
        title: chat.title,
        lastMessagePreview: chat.lastMessagePreview,
        createdAt: chat.updatedAt,
        updatedAt: chat.updatedAt,
      );
      await _firestore.createConversation(
        familyId: familyId,
        conversation: conversation,
      );

      final List<legacy.ChatMessage> legacyMessages = messagesBox.values
          .where((legacy.ChatMessage msg) => msg.chatId == chat.id)
          .toList()
        ..sort((legacy.ChatMessage a, legacy.ChatMessage b) =>
            a.createdAt.compareTo(b.createdAt));

      for (final legacy.ChatMessage message in legacyMessages) {
        final MessageType type = _mapLegacyType(message.type);
        final Map<String, dynamic> openData = <String, dynamic>{
          'text': message.type == legacy.MessageType.text
              ? message.content
              : (message.type == legacy.MessageType.image
                  ? '📷 Image'
                  : '📎 Attachment'),
          'createdAtLocal': message.createdAt.toIso8601String(),
        };
        if (message.storagePath != null && message.storagePath!.isNotEmpty) {
          openData['attachments'] = <String, dynamic>{
            'storagePath': message.storagePath,
            'legacyContent': message.content,
            'type': type.name,
          };
        }
        final Message draft = Message(
          id: message.id,
          conversationId: conversation.id,
          senderId: message.senderId,
          type: type,
          ciphertext: '',
          iv: '',
          encVersion: 0,
          createdAt: message.createdAt,
          status: message.isRead ? MessageStatus.read : MessageStatus.sent,
          openData: openData,
        );
        await _firestore.sendMessage(
          familyId: familyId,
          conversationId: conversation.id,
          draft: draft,
        );
        if (message.isRead) {
          await _firestore.updateMessageStatus(
            familyId: familyId,
            conversationId: conversation.id,
            message: draft,
            status: MessageStatus.read,
          );
        }
      }
    }

    await chatsBox.close();
    await messagesBox.close();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(legacy.ChatAdapter().typeId)) {
      Hive.registerAdapter(legacy.ChatAdapter());
    }
    if (!Hive.isAdapterRegistered(legacy.ChatMessageAdapter().typeId)) {
      Hive.registerAdapter(legacy.ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(legacy.MessageTypeAdapter().typeId)) {
      Hive.registerAdapter(legacy.MessageTypeAdapter());
    }
  }

  MessageType _mapLegacyType(legacy.MessageType type) {
    switch (type) {
      case legacy.MessageType.image:
        return MessageType.image;
      case legacy.MessageType.file:
        return MessageType.file;
      case legacy.MessageType.text:
      default:
        return MessageType.text;
    }
  }
}
