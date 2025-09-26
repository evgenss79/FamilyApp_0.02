import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/message_type.dart';
import '../repositories/chat_messages_repository.dart';
import '../repositories/chats_repository.dart';
import '../services/notifications_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// Provider that manages chats and chat messages via the repository +
/// [SyncService] stack.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatsRepository chatsRepository,
    required ChatMessagesRepository messagesRepository,
    required StorageService storage,
    required SyncService syncService,
    required NotificationsService notificationsService,
    required this.familyId,
  })  : _chatsRepository = chatsRepository,
        _messagesRepository = messagesRepository,
        _storage = storage,
        _syncService = syncService,
        _notifications = notificationsService;

  final ChatsRepository _chatsRepository;
  final ChatMessagesRepository _messagesRepository;
  final StorageService _storage;
  final SyncService _syncService;
  final NotificationsService _notifications;
  final String familyId;
  final List<Chat> _chats = <Chat>[];
  final Map<String, List<ChatMessage>> _messages = <String, List<ChatMessage>>{};


  StreamSubscription<List<Chat>>? _chatsSubscription;
  final Map<String, StreamSubscription<List<ChatMessage>>> _messageSubscriptions =
      <String, StreamSubscription<List<ChatMessage>>>{};
  final Set<String> _subscribedChatIds = <String>{};


  StreamSubscription<List<Chat>>? _chatsSubscription;
  final Map<String, StreamSubscription<List<ChatMessage>>> _messageSubscriptions =
      <String, StreamSubscription<List<ChatMessage>>>{};

  final Set<String> _subscribedChatIds = <String>{};
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
      _chats
        ..clear()
        ..addAll(await _chatsRepository.loadLocal(familyId));
      _messages.clear();
      for (final Chat chat in _chats) {
        _messages[chat.id] = await _messagesRepository.loadLocal(familyId, chat.id);
        if (_subscribedChatIds.add(chat.id)) {
          await _notifications.subscribeToChatTopic(
            familyId: familyId,
            chatId: chat.id,
          );
        }
      }
      _chatsSubscription = _chatsRepository.watchLocal(familyId).listen(
        (List<Chat> updated) {
          final Set<String> updatedIds =
              updated.map((Chat chat) => chat.id).toSet();
          for (final Chat chat in updated) {
            if (_subscribedChatIds.add(chat.id)) {
              unawaited(
                _notifications.subscribeToChatTopic(
                  familyId: familyId,
                  chatId: chat.id,
                ),
              );
            }
          }
          for (final String existing in _subscribedChatIds.toList()) {
            if (!updatedIds.contains(existing)) {
              _subscribedChatIds.remove(existing);
              unawaited(
                _notifications.unsubscribeFromChatTopic(
                  familyId: familyId,
                  chatId: existing,
                ),
              );
            }
          }

          _chats
            ..clear()
            ..addAll(updated);
          _resortChats();
          notifyListeners();
        },
      );
      _loaded = true;
      _resortChats();
      await _syncService.flush();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ChatMessage> messagesByChat(String chatId) {
    _messages.putIfAbsent(chatId, () => <ChatMessage>[]);
    if (!_messageSubscriptions.containsKey(chatId)) {
      _messageSubscriptions[chatId] =
          _messagesRepository.watchLocal(familyId, chatId).listen(
        (List<ChatMessage> updated) {
          _messages[chatId] = updated;
          notifyListeners();
        },
      );
      _messagesRepository.loadLocal(familyId, chatId).then((List<ChatMessage> cached) {
        _messages[chatId] = cached;
        notifyListeners();
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
    await _chatsRepository.saveLocal(familyId, chat);
    _messages[chat.id] = <ChatMessage>[];
    if (_subscribedChatIds.add(chat.id)) {
      await _notifications.subscribeToChatTopic(
        familyId: familyId,
        chatId: chat.id,
      );
    }

    await _syncService.flush();
    _resortChats();
    notifyListeners();
    return chat;
  }

  Future<void> deleteChat(String chatId) async {
    final List<ChatMessage> messages =
        List<ChatMessage>.from(_messages[chatId] ?? await _messagesRepository.loadLocal(familyId, chatId));
    for (final ChatMessage message in messages) {
      if (message.storagePath != null) {
        await _storage.deleteByPath(message.storagePath!);
      }
      await _messagesRepository.markDeleted(familyId, chatId, message.id);
    }
    await _chatsRepository.markDeleted(familyId, chatId);
    await _syncService.flush();
    _messages.remove(chatId);
    await _messageSubscriptions.remove(chatId)?.cancel();
    if (_subscribedChatIds.remove(chatId)) {
      await _notifications.unsubscribeFromChatTopic(
        familyId: familyId,
        chatId: chatId,
      );
    }

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
    await _messagesRepository.saveLocal(familyId, chatId, message);
    await _updateChatMetadata(chatId, updatedAt: now, preview: text);
    await _syncService.flush();
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
    await _messagesRepository.saveLocal(familyId, chatId, message);
    await _updateChatMetadata(chatId, updatedAt: now, preview: preview);
    await _syncService.flush();
    _resortChats();
    notifyListeners();
    return message;
  }

  Future<void> markRead(String chatId) async {
    final List<ChatMessage> messages =
        await _messagesRepository.loadLocal(familyId, chatId);
    bool changed = false;
    final List<ChatMessage> updatedMessages = <ChatMessage>[];
    for (final ChatMessage message in messages) {
      if (message.isRead) {
        updatedMessages.add(message);
        continue;
      }
      final ChatMessage updated = message.copyWith(isRead: true);
      await _messagesRepository.saveLocal(familyId, chatId, updated);
      updatedMessages.add(updated);
      changed = true;
    }
    if (changed) {
      _messages[chatId] = updatedMessages;
      await _syncService.flush();
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
    await _chatsRepository.saveLocal(familyId, updated);
  }

  void _resortChats() {
    _chats.sort((Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    for (final StreamSubscription<List<ChatMessage>> sub
        in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();

    for (final String chatId in _subscribedChatIds) {
      // ANDROID-ONLY FIX: release Android topic subscriptions when provider leaves scope.
      unawaited(
        _notifications.unsubscribeFromChatTopic(
          familyId: familyId,
          chatId: chatId,
        ),
      );
    }
    _subscribedChatIds.clear();
    super.dispose();
  }
}
