import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  static const String chatsBoxName = 'chats_box';
  static const String messagesBoxName = 'messages_box';

  late Box<Chat> _chatsBox;
  late Box<ChatMessage> _messagesBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(ChatAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(ChatMessageAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(MessageTypeAdapter());

    _chatsBox = await Hive.openBox<Chat>(chatsBoxName);
    _messagesBox = await Hive.openBox<ChatMessage>(messagesBoxName);
  }

  List<Chat> get chats {
    final list = _chatsBox.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<ChatMessage> messagesByChat(String chatId) {
    final list = _messagesBox.values.where((m) => m.chatId == chatId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<Chat> createChat({
    required String title,
    required List<String> memberIds,
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

  Future<void> deleteChat(String chatId) async {
    final toDelete = _messagesBox.values.where((m) => m.chatId == chatId).map((m) => m.key).toList();
    await _messagesBox.deleteAll(toDelete);
    await _chatsBox.delete(chatId);
    notifyListeners();
  }

  Future<ChatMessage> sendText({
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

  Future<ChatMessage> sendAttachment({
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
    await _touchChat(chatId, preview: type == MessageType.image ? '📷 Photo' : '📎 File');
    notifyListeners();
    return msg;
  }

  Future<void> markRead(String chatId) async {
    final msgs = _messagesBox.values.where((m) => m.chatId == chatId && !m.isRead).toList();
    for (final m in msgs) {
      m.isRead = true;
      await m.save();
    }
    notifyListeners();
  }

  Future<void> _touchChat(String chatId, {String? preview}) async {
    final chat = _chatsBox.get(chatId);
    if (chat == null) return;
    chat.updatedAt = DateTime.now();
    chat.lastMessagePreview = preview ?? chat.lastMessagePreview;
    await chat.save();
  }
}
