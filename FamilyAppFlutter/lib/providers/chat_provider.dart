import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

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

  final List<Conversation> _conversations = <Conversation>[];
  final Map<String, List<Message>> _messages = <String, List<Message>>{};
  final Map<String, bool> _messagesInitialized = <String, bool>{};

  StreamSubscription<List<Conversation>>? _conversationsSub;
  final Map<String, StreamSubscription<List<Message>>> _messageSubs =
      <String, StreamSubscription<List<Message>>>{};

  final Uuid _uuid = const Uuid();

  bool _initialized = false;
  bool _loading = false;

  bool get isLoading => _loading;

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  List<Conversation> get chats => conversations;


  List<Message> messagesFor(String conversationId) {
    _ensureMessagesSubscription(conversationId);
    return List.unmodifiable(_messages[conversationId] ?? const <Message>[]);
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _loading = true;
    notifyListeners();

    final List<Conversation> cached =
        await _firestore.loadCachedConversations(familyId);
    _conversations
      ..clear()
      ..addAll(cached);

    _conversationsSub = _firestore
        .watchConversations(familyId)
        .listen((List<Conversation> data) {
      _conversations
        ..clear()
        ..addAll(data)
        ..sort((Conversation a, Conversation b) {
          final DateTime aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
      notifyListeners();
    });

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<Conversation> createChat({
    required String title,
    required List<String> memberIds,
  }) =>
      createConversation(participantIds: memberIds, title: title);

  Future<void> deleteChat(String chatId) => deleteConversation(chatId);
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? title,
    String? avatarUrl,
  }) async {
    final Conversation conversation = Conversation(
      id: _uuid.v4(),
      participantIds: participantIds,
      title: title,
      avatarUrl: avatarUrl,
      lastMessagePreview: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _conversations.insert(0, conversation);
    notifyListeners();
    await _firestore.createConversation(
      familyId: familyId,
      conversation: conversation,
    );
    return conversation;
  }

  Future<Message> sendText({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final Message draft = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      type: MessageType.text,
      ciphertext: '',
      iv: '',
      encVersion: 0,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      openData: <String, dynamic>{'text': text},
    );
    _addOptimisticMessage(conversationId, draft);
    try {
      final Message stored = await _firestore.sendMessage(
        familyId: familyId,
        conversationId: conversationId,
        draft: draft,
      );
      _replaceOptimisticMessage(
        conversationId,
        draft.id,
        stored.copyWith(status: MessageStatus.sent),
      );
      notifyListeners();
      return stored;
    } catch (error) {
      _removeOptimisticMessage(conversationId, draft.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<Message> sendAttachment({
    required String conversationId,
    required String senderId,
    required String localPath,
    required MessageType type,
  }) async {
    if (type == MessageType.text) {
      throw ArgumentError('Attachment must be an image or file message');
    }
    final File file = File(localPath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $localPath');
    }
    final StorageUploadResult upload = await _storage.uploadChatAttachment(
      familyId: familyId,
      conversationId: conversationId,
      file: file,
    );
    final String preview =
        type == MessageType.image ? '📷 Image' : '📎 Attachment';
    final Message draft = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      type: type,
      ciphertext: '',
      iv: '',
      encVersion: 0,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      openData: <String, dynamic>{
        'text': preview,
        'attachments': <String, dynamic>{
          'url': upload.downloadUrl,
          'storagePath': upload.storagePath,
          'type': type.name,
        },
      },
    );
    _addOptimisticMessage(conversationId, draft);
    try {
      final Message stored = await _firestore.sendMessage(
        familyId: familyId,
        conversationId: conversationId,
        draft: draft,
      );
      _replaceOptimisticMessage(
        conversationId,
        draft.id,
        stored.copyWith(status: MessageStatus.sent),
      );
      notifyListeners();
      return stored;
    } catch (error) {
      _removeOptimisticMessage(conversationId, draft.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final List<Message> list = List<Message>.from(_messages[conversationId] ?? const <Message>[]);
    for (final Message message in list) {
      if (message.status != MessageStatus.read) {
        await _firestore.updateMessageStatus(
          familyId: familyId,
          conversationId: conversationId,
          message: message,
          status: MessageStatus.read,
        );
      }
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((Conversation c) => c.id == conversationId);
    final List<Message>? existing = _messages.remove(conversationId);
    notifyListeners();
    if (existing != null) {
      for (final Message message in existing) {
        final Map<String, dynamic>? attachments =
            message.openData['attachments'] as Map<String, dynamic>?;
        final String? storagePath = attachments?['storagePath'] as String?;
        if (storagePath != null && storagePath.isNotEmpty) {
          await _storage.deleteByPath(storagePath);
        }
      }
    }
    _messageSubs.remove(conversationId)?.cancel();
    _messagesInitialized.remove(conversationId);
    await _firestore.deleteConversation(familyId, conversationId);
  }

  void _ensureMessagesSubscription(String conversationId) {
    if (_messagesInitialized[conversationId] == true) {
      return;
    }
    _messagesInitialized[conversationId] = true;
    _loadCachedMessages(conversationId);
    final StreamSubscription<List<Message>> sub = _firestore
        .watchMessages(
          familyId: familyId,
          conversationId: conversationId,
        )
        .listen((List<Message> data) async {
      _messages[conversationId] = data;
      notifyListeners();
      for (final Message message in data) {
        if (message.status == MessageStatus.sent) {
          unawaited(_firestore.updateMessageStatus(
            familyId: familyId,
            conversationId: conversationId,
            message: message,
            status: MessageStatus.delivered,
          ));
        }
      }
    });
    _messageSubs[conversationId] = sub;
  }

  Future<void> _loadCachedMessages(String conversationId) async {
    final List<Message> cached =
        await _firestore.loadCachedMessages(familyId, conversationId);
    if (cached.isNotEmpty) {
      _messages[conversationId] = cached;
      notifyListeners();
    }
  }

  void _addOptimisticMessage(String conversationId, Message message) {
    final List<Message> list =
        _messages.putIfAbsent(conversationId, () => <Message>[]);
    list.add(message);
    notifyListeners();
  }

  void _replaceOptimisticMessage(
    String conversationId,
    String tempId,
    Message replacement,
  ) {
    final List<Message>? list = _messages[conversationId];
    if (list == null) {
      return;
    }
    final int index = list.indexWhere((Message m) => m.id == tempId);
    if (index != -1) {
      list[index] = replacement;
    }
  }

  void _removeOptimisticMessage(String conversationId, String messageId) {
    final List<Message>? list = _messages[conversationId];
    list?.removeWhere((Message m) => m.id == messageId);
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    for (final StreamSubscription<List<Message>> sub in _messageSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
