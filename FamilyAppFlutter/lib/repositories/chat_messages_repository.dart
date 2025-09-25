import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../security/encrypted_firestore_service.dart';
import '../storage/local_store.dart';
import '../utils/parsing.dart';

class ChatMessagesRepository {
  ChatMessagesRepository({
    FirebaseFirestore? firestore,
    EncryptedFirestoreService? encryption,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryption = encryption ?? const EncryptedFirestoreService();

  final FirebaseFirestore _firestore;
  final EncryptedFirestoreService _encryption;

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _listeners = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  Future<List<ChatMessage>> loadLocal(String familyId, String chatId) async {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    final Iterable<Map<String, dynamic>> messages = box.values.where(
      (Map<String, dynamic> value) => value['chatId'] == chatId,
    );
    return messages
        .map((Map<String, dynamic> map) => ChatMessage.fromMap(map))
        .toList()
      ..sort((ChatMessage a, ChatMessage b) => a.createdAt.compareTo(b.createdAt));
  }

  Stream<List<ChatMessage>> watchLocal(String familyId, String chatId) async* {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    Iterable<Map<String, dynamic>> readAll() => box.values.where(
          (Map<String, dynamic> value) => value['chatId'] == chatId,
        );
    yield readAll()
        .map((Map<String, dynamic> map) => ChatMessage.fromMap(map))
        .toList()
      ..sort((ChatMessage a, ChatMessage b) => a.createdAt.compareTo(b.createdAt));
    yield* box.watch().map((_) {
      return readAll()
          .map((Map<String, dynamic> map) => ChatMessage.fromMap(map))
          .toList()
        ..sort((ChatMessage a, ChatMessage b) =>
            a.createdAt.compareTo(b.createdAt));
    });
  }

  Future<ChatMessage> saveLocal(
    String familyId,
    String chatId,
    ChatMessage message, {
    bool pending = true,
  }) async {
    final map = Map<String, dynamic>.from(message.toMap())
      ..['chatId'] = chatId
      ..['_pending'] = pending
      ..['familyId'] = familyId
      ..['updatedAt'] = message.createdAt.toIso8601String();
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    await box.put(_messageKey(chatId, message.id), map);
    return ChatMessage.fromMap(map);
  }

  Future<void> markDeleted(
    String familyId,
    String chatId,
    String messageId,
  ) async {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    await box.delete(_messageKey(chatId, messageId));
    final deleteBox = await LocalStore.openBox<String>(
      _deleteBoxName(familyId),
    );
    await deleteBox.put(_messageKey(chatId, messageId), chatId);
  }

  Future<void> pullRemote(String familyId, String chatId) async {
    final snapshot = await _messagesCollection(familyId, chatId).get();
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    for (final doc in snapshot.docs) {
      final data = await _decode(doc);
      data['_pending'] = false;
      await box.put(_messageKey(chatId, doc.id), data);
    }
  }

  Future<void> pushPending(String familyId) async {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    final pendingEntries = box.toMap().entries.where(
      (MapEntry<dynamic, dynamic> entry) =>
          entry.value is Map && entry.value['_pending'] == true,
    );
    final deleteBox = await LocalStore.openBox<String>(
      _deleteBoxName(familyId),
    );
    final deletions = deleteBox.toMap();
    if (pendingEntries.isEmpty && deletions.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();

    for (final entry in pendingEntries) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
      final String key = entry.key.toString();
      final parts = key.split('::');
      if (parts.length != 2) {
        continue;
      }
      final String chatId = parts.first;
      final String messageId = parts.last;
      final Map<String, dynamic> payload = await _encryption.encryptPayload(
        Map<String, dynamic>.from(data)..remove('_pending'),
      )
        ..['chatId'] = chatId
        ..['familyId'] = familyId
        ..['createdAt'] = data['createdAt']
        ..['updatedAt'] = data['updatedAt'];
      batch.set(
        _messagesCollection(familyId, chatId).doc(messageId),
        payload,
        SetOptions(merge: true),
      );
    }

    for (final MapEntry<dynamic, dynamic> entry in deletions.entries) {
      final String key = entry.key.toString();
      final List<String> parts = key.split('::');
      if (parts.length != 2) {
        continue;
      }
      batch.delete(
        _messagesCollection(familyId, parts.first).doc(parts.last),
      );
    }

    await batch.commit();

    for (final entry in pendingEntries) {
      final Map<String, dynamic> map =
          Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
      map['_pending'] = false;
      await box.put(entry.key, map);
    }
    await deleteBox.clear();
  }

  Future<void> listenForChat(String familyId, String chatId) async {
    final String key = _listenerKey(familyId, chatId);
    if (_listeners.containsKey(key)) {
      return;
    }
    final subscription = _messagesCollection(familyId, chatId).snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        for (final change in snapshot.docChanges) {
          await _applyRemoteChange(familyId, chatId, change);
        }
      },
    );
    _listeners[key] = subscription;
  }

  Future<void> dispose() async {
    for (final subscription in _listeners.values) {
      await subscription.cancel();
    }
    _listeners.clear();
  }

  Future<void> cancelForChat(String familyId, String chatId) async {
    final String key = _listenerKey(familyId, chatId);
    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
        subscription = _listeners.remove(key);
    await subscription?.cancel();
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String familyId,
    String chatId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('chats')
        .doc(chatId)
        .collection('messages');
  }

  Future<void> _applyRemoteChange(
    String familyId,
    String chatId,
    DocumentChange<Map<String, dynamic>> change,
  ) async {
    final String id = change.doc.id;
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    if (change.type == DocumentChangeType.removed) {
      await box.delete(_messageKey(chatId, id));
      return;
    }
    final data = await _decode(change.doc);
    final existing = box.get(_messageKey(chatId, id));
    if (existing != null) {
      final DateTime? localUpdated =
          parseNullableDateTime(existing['updatedAt']);
      final DateTime? remoteUpdated =
          parseNullableDateTime(data['updatedAt']);
      if (existing['_pending'] == true &&
          (remoteUpdated == null ||
              (localUpdated != null &&
                  remoteUpdated.isBefore(localUpdated)))) {
        final payload = await _encryption.encryptPayload(
          Map<String, dynamic>.from(existing)..remove('_pending'),
        )
          ..['chatId'] = chatId
          ..['familyId'] = familyId
          ..['createdAt'] = existing['createdAt']
          ..['updatedAt'] = existing['updatedAt'];
        await _messagesCollection(familyId, chatId)
            .doc(id)
            .set(payload, SetOptions(merge: true));
        return;
      }
      if (remoteUpdated != null &&
          localUpdated != null &&
          remoteUpdated.isBefore(localUpdated)) {
        final payload = await _encryption.encryptPayload(
          Map<String, dynamic>.from(existing)..remove('_pending'),
        )
          ..['chatId'] = chatId
          ..['familyId'] = familyId
          ..['createdAt'] = existing['createdAt']
          ..['updatedAt'] = existing['updatedAt'];
        await _messagesCollection(familyId, chatId)
            .doc(id)
            .set(payload, SetOptions(merge: true));
        return;
      }
    }
    data['_pending'] = false;
    await box.put(_messageKey(chatId, id), data);
  }

  Future<Map<String, dynamic>> _decode(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final decoded = await _encryption.decode(doc.data());
    decoded['id'] = doc.id;
    decoded['chatId'] ??= doc.reference.parent.parent?.id;
    decoded['updatedAt'] ??= decoded['createdAt'] ??
        DateTime.now().toUtc().toIso8601String();
    return decoded;
  }

  String _boxName(String familyId) => 'chat_messages_$familyId';

  String _deleteBoxName(String familyId) => 'chat_messages_${familyId}__deletes';

  String _messageKey(String chatId, String messageId) => '$chatId::$messageId';

  String _listenerKey(String familyId, String chatId) => '$familyId::$chatId';
}

