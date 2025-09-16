import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_storage_service.dart';
import '../services/firestore_service.dart';

/// Provider that manages chat conversations and messages.
///
/// Stores data locally using [ChatStorageServiceV001] and optionally
/// synchronizes with Firestore via [FirestoreService]. New helper
/// methods [setConversations] and [setMessages] have been added to
/// facilitate replacing local lists from a remote source during
/// synchronization.
class ChatDataV001 with ChangeNotifier {
  // Основные списки данных
  List<Conversation> _conversations = [];
  List<Message> _messages = [];

  // Сервис Firestore и идентификатор семьи
  final FirestoreService _firestoreService = FirestoreService();
  String? familyId;

  // Геттеры
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  /// Read‑only список всех сообщений.
  List<Message> get messages => List.unmodifiable(_messages);

  /// Возвращает список сообщений, принадлежащих заданному разговору.
  List<Message> messagesForConversation(String conversationId) {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  /// Первичная инициализация: familyId + локальная загрузка + подтяжка из Firestore.
  Future<void> initialize(String id) async {
    familyId = id;
    await loadData();
    try {
      await loadFromFirestore();
    } catch (_) {
      // Не роняем UI при сетевой ошибке — останемся на локальных данных
    }
  }

  /// Загрузка данных из локального хранилища (Hive).
  Future<void> loadData() async {
    await ChatStorageServiceV001.init();
    _conversations = ChatStorageServiceV001.loadConversations();
    _messages = ChatStorageServiceV001.loadMessages();
    notifyListeners();
  }

  /// Добавляет разговор локально и синхронизирует его при наличии familyId.
  Future<void> addConversation(Conversation conversation) async {
    _conversations.add(conversation);
    ChatStorageServiceV001.saveConversations(_conversations);
    notifyListeners();
    if (familyId != null) {
      try {
        await saveToFirestore();
      } catch (_) {}
    }
  }

  /// Добавляет сообщение и обновляет lastMessageTime у соответствующего разговора.
  Future<void> addMessage(Message message) async {
    _messages.add(message);
    ChatStorageServiceV001.saveMessages(_messages);
    final index = _conversations.indexWhere((c) => c.id == message.conversationId);
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
    if (familyId != null) {
      try {
        await saveToFirestore();
      } catch (_) {}
    }
  }

  /// Удаляет разговор и все его сообщения.
  Future<void> removeConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
    ChatStorageServiceV001.saveConversations(_conversations);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
    if (familyId != null) {
      try {
        await saveToFirestore();
      } catch (_) {}
    }
  }

  /// Удаляет одно сообщение.
  Future<void> removeMessage(String messageId) async {
    _messages.removeWhere((m) => m.id == messageId);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
    if (familyId != null) {
      try {
        await saveToFirestore();
      } catch (_) {}
    }
  }

  /// Загружает разговоры и сообщения из Firestore.
  Future<void> loadFromFirestore() async {
    if (familyId == null) return;
    _conversations = await _firestoreService.fetchConversations(familyId!);
    _messages = [];
    for (final conversation in _conversations) {
      final msgs = await _firestoreService.fetchMessages(familyId!, conversation.id);
      _messages.addAll(msgs);
    }
    notifyListeners();
  }

  /// Сохраняет все разговоры и сообщения в Firestore.
  Future<void> saveToFirestore() async {
    if (familyId == null) return;
    await _firestoreService.saveConversations(familyId!, _conversations);
    // Группируем сообщения по разговору
    final Map<String, List<Message>> messagesByConversation = {};
    for (final msg in _messages) {
      messagesByConversation.putIfAbsent(msg.conversationId, () => []);
      messagesByConversation[msg.conversationId]!.add(msg);
    }
    for (final entry in messagesByConversation.entries) {
      await _firestoreService.saveMessages(
        familyId!,
        entry.key,
        entry.value,
      );
    }
  }

  /// Заменяет список разговоров и уведомляет слушателей.
  void setConversations(List<Conversation> conversations) {
    _conversations = List.from(conversations);
    ChatStorageServiceV001.saveConversations(_conversations);
    notifyListeners();
  }

  /// Заменяет список сообщений и уведомляет слушателей.
  void setMessages(List<Message> messages) {
    _messages = List.from(messages);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
  }
}
