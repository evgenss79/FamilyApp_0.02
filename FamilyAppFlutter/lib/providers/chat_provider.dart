import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/message_type.dart';
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

  final List<Chat> _chats = <Chat>[];
  final Map<String, List<ChatMessage>> _messages = <String, List<ChatMessage>>{};
  final Set<String> _loadedChatMessages = <String>{};
  final Set<String> _loadingChatMessages = <String>{};

  final Uuid _uuid = const Uuid();

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Chat> get chats => List.unmodifiable(_chats);

  Future<void> init() async => load();

  Future<void> load() async {
    if (_loaded || _isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final List<Chat> fetchedChats = await _firestore.fetchChats(familyId);
      _chats
        ..clear()
        ..addAll(fetchedChats);
      _messages.clear();
      for (final Chat chat in _chats) {
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
      _firestore.fetchChatMessages(familyId, chatId).then((List<ChatMessage> messages) {
        _messages[chatId] = List<ChatMessage>.from(messages);
        _loadedChatMessages.add(chatId);
        _loadingChatMessages.remove(chatId);
        notifyListeners();
      }).catchError((_) {
        _loadingChatMessages.remove(chatId);
      });
    }
    return List.unmodifiable(_messages[chatId] ?? const <ChatMessage>[]);
  }

  Future<Chat> createChat({
    required String title,
    required List<String> memberIds,
  }) async {
    final DateTime now = DateTime.now();
    final Chat chat = Chat(
      id: _uuid.v4(),
      title: title,
      memberIds: memberIds,
      updatedAt: now,
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
    final List<ChatMessage> messages = _loadedChatMessages.contains(chatId)
        ? List<ChatMessage>.from(_messages[chatId] ?? const <ChatMessage>[])
        : await _firestore.fetchChatMessages(familyId, chatId);
    for (final ChatMessage message in messages) {
      if (message.storagePath != null) {
        await _storage.deleteByPath(message.storagePath!);
      }
    }
    await _firestore.deleteChatMessages(familyId, chatId);
    await _firestore.deleteChat(familyId, chatId);
    _messages.remove(chatId);
    _loadedChatMessages.remove(chatId);
    _chats.removeWhere((Chat chat) => chat.id == chatId);
    notifyListeners();
  }

  Future<ChatMessage> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final DateTime now = DateTime.now();
    final ChatMessage message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: text,
      createdAt: now,
      type: MessageType.text,
      isRead: false,
    );
    await _firestore.upsertChatMessage(familyId, chatId, message);
    await _updateChatMetadata(chatId, updatedAt: now, preview: text);
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
    final File file = File(localPath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $localPath');
    }
    final StorageUploadResult upload = await _storage.uploadChatAttachment(
      familyId: familyId,
      chatId: chatId,
      file: file,
    );
    final DateTime now = DateTime.now();
    final String preview = type == MessageType.image ? '📷 Photo' : '📎 File';
    final ChatMessage message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: upload.downloadUrl,
      createdAt: now,
      type: type,
      isRead: false,
      storagePath: upload.storagePath,
    );
    await _firestore.upsertChatMessage(familyId, chatId, message);
    await _updateChatMetadata(chatId, updatedAt: now, preview: preview);
    _messages.putIfAbsent(chatId, () => <ChatMessage>[]).add(message);
    _loadedChatMessages.add(chatId);
    _resortChats();
    notifyListeners();
    return message;
  }

  Future<void> markRead(String chatId) async {
    final List<ChatMessage> messages =
        await _firestore.fetchChatMessages(familyId, chatId);
    bool changed = false;
    final List<ChatMessage> updatedMessages = <ChatMessage>[];
    for (final ChatMessage message in messages) {
      if (message.isRead) {
        updatedMessages.add(message);
        continue;
      }
      final ChatMessage updated = message.copyWith(isRead: true);
      await _firestore.upsertChatMessage(familyId, chatId, updated);
      updatedMessages.add(updated);
      changed = true;
    }
    if (changed) {
      _messages[chatId] = updatedMessages;
      _loadedChatMessages.add(chatId);
      notifyListeners();
    }
  }

  Future<void> _updateChatMetadata(String chatId,
      {required DateTime updatedAt, String? preview}) async {
    final int index = _chats.indexWhere((Chat chat) => chat.id == chatId);
    if (index == -1) {
      return;
    }
    final Chat updated = _chats[index].copyWith(
      updatedAt: updatedAt,
      lastMessagePreview: preview,
    );
    _chats[index] = updated;
    await _firestore.upsertChat(familyId, updated);
  }

  void _resortChats() {
    _chats.sort((Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
