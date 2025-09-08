import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_storage_service.dart';
import '../services/firestore_service.dart';

class ChatDataV001 with ChangeNotifier {
  // ---- Состояние ------------------------------------------------------------
  List<Conversation> _conversations = [];
  List<Message> _messages = [];

  // ---- Сервисы --------------------------------------------------------------
  final FirestoreService _firestoreService = FirestoreService();
  String? familyId;

  // ---- Геттеры --------------------------------------------------------------
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  List<Message> messagesForConversation(String conversationId) {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  // ---- Локальная загрузка (Hive) -------------------------------------------
  Future<void> loadData() async {
    await ChatStorageServiceV001.init();
    _conversations = ChatStorageServiceV001.loadConversations();
    _messages = ChatStorageServiceV001.loadMessages();
    notifyListeners();
  }

  // ---- Добавление разговора -------------------------------------------------
  void addConversation(Conversation conversation) {
    _conversations.add(conversation);
    ChatStorageServiceV001.saveConversations(_conversations);
    notifyListeners();
  }

  // ---- Добавление сообщения -------------------------------------------------
  void addMessage(Message message) {
    _messages.add(message);
    ChatStorageServiceV001.saveMessages(_messages);

    // Обновляем lastMessageTime у соответствующего Conversation
    final index =
        _conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      final conv = _conversations[index];
      _conversations[index] = Conversation(
        id: conv.id,
        title: conv.title,
        memberIds: conv.memberIds,
        createdAt: conv.createdAt,
        lastMessageTime: message.timestamp,
      );
      ChatStorageServiceV001.saveConversations(_conversations);
    }
    notifyListeners();
  }

  // ---- Удаление разговора (и его сообщений) --------------------------------
  void removeConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
    ChatStorageServiceV001.saveConversations(_conversations);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
  }

  // ---- Удаление сообщения ---------------------------------------------------
  void removeMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
  }

  // ---- Загрузка из Firestore -----------------------------------------------
  /// Загружает разговоры и сообщения из Firestore для текущей семьи.
  Future<void> loadFromFirestore() async {
    if (familyId == null) return;

    // 1) разговоры семьи
    _conversations = await _firestoreService.fetchConversations(familyId!);

    // 2) сообщения по каждому разговору
    _messages = [];
    for (final conversation in _conversations) {
      final msgs =
          await _firestoreService.fetchMessages(familyId!, conversation.id);
      _messages.addAll(msgs);
    }

    notifyListeners();
  }

  // ---- Сохранение в Firestore ----------------------------------------------
  /// Сохраняет все разговоры и их сообщения в Firestore.
  Future<void> saveToFirestore() async {
    if (familyId == null) return;

    // 1) разговоры
    await _firestoreService.saveConversations(familyId!, _conversations);

    // 2) группируем сообщения по conversationId для батч-записи
    final Map<String, List<Message>> messagesByConversation = {};
    for (final msg in _messages) {
      messagesByConversation.putIfAbsent(msg.conversationId, () => []);
      messagesByConversation[msg.conversationId]!.add(msg);
    }

    // 3) сохраняем сообщения для каждого разговора
    for (final entry in messagesByConversation.entries) {
      await _firestoreService.saveMessages(
        familyId!,
        entry.key,    // conversationId
        entry.value,  // список сообщений
      );
    }
  }
}
