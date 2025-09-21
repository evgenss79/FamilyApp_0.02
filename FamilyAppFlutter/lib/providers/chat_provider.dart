import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';

/// Provider that manages chats and chat messages.  It persists data via
/// Hive and exposes methods to create, delete and send messages.  The
/// adapters for Chat, ChatMessage and MessageType are registered during
/// initialization if they have not been registered already.
class ChatProvider extends ChangeNotifier {
  static const String chatsBoxName = 'chats_box';
  static const String messagesBoxName = 'messages_box';

  late Box _chatsBox;
  late Box _messagesBox;

  final _uuid = const Uuid();

  Future init() async {
    // Register Hive adapters if they haven't been registered yet.  Each
    // registration is wrapped in a block to satisfy lint rules about
    // curly braces around single-statement ifs.
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ChatAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }

    _chatsBox = await Hive.openBox(chatsBoxName);
    _messagesBox = await Hive.openBox(messagesBoxName);
  }

  List get chats {
    final list = _chatsBox.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List messagesByChat(String chatId) {
    final list = _messagesBox.values.where((m) => m.chatId == chatId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future createChat({
    required String title,
    required List memberIds,
  }) async {
    final chat = Chat(
      id: _uuid.v4(),
      title: title,
      memberIds: memberIds,
      updatedAt: DateTime.now(),
      lastMessagePreview: null,
    );
    await _chatsBox.put(chat.id, chat);
    notifyListeners();
    return chat;
  }

  Future deleteChat(String chatId) async {
    final toDelete = _messagesBox.values
        .where((m) => m.chatId == chatId)
        .map((m) => m.key)
        .toList();
    await _messagesBox.deleteAll(toDelete);
    await _chatsBox.delete(chatId);
    notifyListeners();
  }

  Future sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: text,
      createdAt: DateTime.now(),
      type: MessageType.text,
      isRead: false,
    );
    await _messagesBox.put(msg.id, msg);
    await _touchChat(chatId, preview: text);
    notifyListeners();
    return msg;
  }

  Future sendAttachment({
    required String chatId,
    required String senderId,
    required String localPath,
    required MessageType type,
  }) async {
    if (type == MessageType.text) {
      throw ArgumentError('Attachment must be image or file');
    }
    if (!await File(localPath).exists()) {
      throw ArgumentError('File not found: $localPath');
    }
    final msg = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: localPath,
      createdAt: DateTime.now(),
      type: type,
      isRead: false,
    );
    await _messagesBox.put(msg.id, msg);
    await _touchChat(
      chatId,
      preview: type == MessageType.image ? '📷 Photo' : '📎 File',
    );
    notifyListeners();
    return msg;
  }

  Future markRead(String chatId) async {
    final msgs = _messagesBox.values
        .where((m) => m.chatId == chatId && !m.isRead)
        .toList();
    for (final m in msgs) {
      m.isRead = true;
      await m.save();
    }
    notifyListeners();
  }

  Future _touchChat(String chatId, {String? preview}) async {
    final chat = _chatsBox.get(chatId);
    if (chat == null) return;
    chat.updatedAt = DateTime.now();
    chat.lastMessagePreview = preview ?? chat.lastMessagePreview;
    await chat.save();
  }
}