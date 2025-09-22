import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Provider that manages chats and chat messages backed by Firestore.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required FirestoreService firestore,
    required StorageService storage,
    required this.familyId,
  })  : _firestore = firestore,
        _storage = storage;

  final FirestoreService _firestore;
  final StorageService _storage;
  final String familyId;

  final List<Chat> _chats = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _loadedChatMessages = <String>{};
  final Set<String> _loadingChatMessages = <String>{};

  final Uuid _uuid = const Uuid();

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Chat> get chats => List.unmodifiable(_chats);

  Future<void> init() async => load();

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedChats = await _firestore.fetchChats(familyId);
      _chats
        ..clear()
        ..addAll(fetchedChats);
      _messages.clear();
      for (final chat in _chats) {
        _messages[chat.id] = <ChatMessage>[];
      }
      _loaded = true;
      _resortChats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ChatMessage> messagesByChat(String chatId) {
    if (!_loadedChatMessages.contains(chatId) &&
        !_loadingChatMessages.contains(chatId)) {
      _loadingChatMessages.add(chatId);
      _firestore.fetchChatMessages(familyId, chatId).then((messages) {
        _messages[chatId] = messages;
        _loadedChatMessages.add(chatId);
        _loadingChatMessages.remove(chatId);
        notifyListeners();
      }).catchError((_) {
        _loadingChatMessages.remove(chatId);
      });
    }
    return List.unmodifiable(_messages[chatId] ?? const []);
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
    await _firestore.upsertChat(familyId, chat);
    _chats.add(chat);
    _messages[chat.id] = <ChatMessage>[];
    _loadedChatMessages.add(chat.id);
    _resortChats();
    notifyListeners();
    return chat;
  }

  Future<void> deleteChat(String chatId) async {
    final messages = _loadedChatMessages.contains(chatId)
        ? List<ChatMessage>.from(_messages[chatId] ?? const [])
        : await _firestore.fetchChatMessages(familyId, chatId);
    for (final message in messages) {
      if (message.storagePath != null) {
        await _storage.deleteByPath(message.storagePath!);
      }
    }
    await _firestore.deleteChatMessages(familyId, chatId);
    await _firestore.deleteChat(familyId, chatId);
    _messages.remove(chatId);
    _loadedChatMessages.remove(chatId);
    _chats.removeWhere((chat) => chat.id == chatId);
    notifyListeners();
  }

  Future<ChatMessage> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: text,
      createdAt: DateTime.now(),
      type: MessageType.text,
      isRead: false,
    );
    await _firestore.upsertChatMessage(familyId, chatId, message);
    final chat = _chats.firstWhere((c) => c.id == chatId, orElse: () => throw ArgumentError('Chat not found'));
    chat.updatedAt = DateTime.now();
    chat.lastMessagePreview = text;
    await _firestore.upsertChat(familyId, chat);
    _messages.putIfAbsent(chatId, () => <ChatMessage>[]).add(message);
    _loadedChatMessages.add(chatId);
    _resortChats();
    notifyListeners();
    return message;
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
    final file = File(localPath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $localPath');
    }
    final upload = await _storage.uploadChatAttachment(
      familyId: familyId,
      chatId: chatId,
      file: file,
    );
    final preview = type == MessageType.image ? '📷 Photo' : '📎 File';
    final message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: upload.downloadUrl,
      createdAt: DateTime.now(),
      type: type,
      isRead: false,
      storagePath: upload.storagePath,
    );
    await _firestore.upsertChatMessage(familyId, chatId, message);
    final chat = _chats.firstWhere((c) => c.id == chatId, orElse: () => throw ArgumentError('Chat not found'));
    chat.updatedAt = DateTime.now();
    chat.lastMessagePreview = preview;
    await _firestore.upsertChat(familyId, chat);
    _messages.putIfAbsent(chatId, () => <ChatMessage>[]).add(message);
    _loadedChatMessages.add(chatId);
    _resortChats();
    notifyListeners();
    return message;
  }

  Future<void> markRead(String chatId) async {
    final messages = await _firestore.fetchChatMessages(familyId, chatId);
    bool changed = false;
    for (final message in messages) {
      if (!message.isRead) {
        message.isRead = true;
        await _firestore.upsertChatMessage(familyId, chatId, message);
        changed = true;
      }
    }
    if (changed) {
      _messages[chatId] = messages;
      _loadedChatMessages.add(chatId);
      notifyListeners();
    }
  }

  void _resortChats() {
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
