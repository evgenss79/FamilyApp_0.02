import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../security/encrypted_firestore_service.dart';
import '../storage/local_store.dart';
import '../utils/parsing.dart';

class CallMessagesRepository {
  CallMessagesRepository({
    FirebaseFirestore? firestore,
    EncryptedFirestoreService? encryption,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryption = encryption ?? const EncryptedFirestoreService();

  final FirebaseFirestore _firestore;
  final EncryptedFirestoreService _encryption;

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _listeners = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  Future<List<Message>> loadLocal(String familyId, String callId) async {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    final Iterable<Map<String, dynamic>> values = box.values.where(
      (Map<String, dynamic> value) => value['conversationId'] == callId,
    );
    return values
        .map((Map<String, dynamic> value) => Message.fromMap(value))
        .toList()
      ..sort((Message a, Message b) => a.createdAt.compareTo(b.createdAt));
  }

  Stream<List<Message>> watchLocal(String familyId, String callId) async* {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    Iterable<Map<String, dynamic>> readAll() => box.values.where(
          (Map<String, dynamic> value) => value['conversationId'] == callId,
        );
    yield readAll()
        .map((Map<String, dynamic> value) => Message.fromMap(value))
        .toList()
      ..sort((Message a, Message b) => a.createdAt.compareTo(b.createdAt));
    yield* box.watch().map((_) {
      return readAll()
          .map((Map<String, dynamic> value) => Message.fromMap(value))
          .toList()
        ..sort((Message a, Message b) =>
            a.createdAt.compareTo(b.createdAt));
    });
  }

  Future<Message> saveLocal(
    String familyId,
    String callId,
    Message message, {
    bool pending = true,
  }) async {
    final map = Map<String, dynamic>.from(message.toMap())
      ..['conversationId'] = callId
      ..['_pending'] = pending
      ..['familyId'] = familyId
      ..['updatedAt'] = message.createdAt.toIso8601String();
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    await box.put(_messageKey(callId, message.id), map);
    return Message.fromMap(map);
  }

  Future<void> markDeleted(
    String familyId,
    String callId,
    String messageId,
  ) async {
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    await box.delete(_messageKey(callId, messageId));
    final deleteBox = await LocalStore.openBox<String>(
      _deleteBoxName(familyId),
    );
    await deleteBox.put(_messageKey(callId, messageId), callId);
  }

  Future<void> pullRemote(String familyId, String callId) async {
    final snapshot = await _messagesCollection(familyId, callId).get();
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    for (final doc in snapshot.docs) {
      final data = await _decode(doc);
      data['_pending'] = false;
      await box.put(_messageKey(callId, doc.id), data);
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
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        entry.value as Map<dynamic, dynamic>,
      );
      final String key = entry.key.toString();
      final parts = key.split('::');
      if (parts.length != 2) {
        continue;
      }
      final String callId = parts.first;
      final String messageId = parts.last;
      final Map<String, dynamic> payload = await _encryption.encryptPayload(
        Map<String, dynamic>.from(data)..remove('_pending'),
      )
        ..['conversationId'] = callId
        ..['familyId'] = familyId
        ..['createdAt'] = data['createdAt']
        ..['updatedAt'] = data['updatedAt'];
      batch.set(
        _messagesCollection(familyId, callId).doc(messageId),
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
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        entry.value as Map<dynamic, dynamic>,
      );
      map['_pending'] = false;
      await box.put(entry.key, map);
    }
    await deleteBox.clear();
  }

  Future<void> listenForCall(String familyId, String callId) async {
    final String key = _listenerKey(familyId, callId);
    if (_listeners.containsKey(key)) {
      return;
    }
    final subscription = _messagesCollection(familyId, callId).snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        for (final change in snapshot.docChanges) {
          await _applyRemoteChange(familyId, callId, change);
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

  Future<void> cancelForCall(String familyId, String callId) async {
    final String key = _listenerKey(familyId, callId);
    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
        subscription = _listeners.remove(key);
    await subscription?.cancel();
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String familyId,
    String callId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('calls')
        .doc(callId)
        .collection('messages');
  }

  Future<void> _applyRemoteChange(
    String familyId,
    String callId,
    DocumentChange<Map<String, dynamic>> change,
  ) async {
    final String id = change.doc.id;
    final box = await LocalStore.openBox<Map<String, dynamic>>(
      _boxName(familyId),
    );
    if (change.type == DocumentChangeType.removed) {
      await box.delete(_messageKey(callId, id));
      return;
    }
    final data = await _decode(change.doc);
    final existing = box.get(_messageKey(callId, id));
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
          ..['conversationId'] = callId
          ..['familyId'] = familyId
          ..['createdAt'] = existing['createdAt']
          ..['updatedAt'] = existing['updatedAt'];
        await _messagesCollection(familyId, callId)
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
          ..['conversationId'] = callId
          ..['familyId'] = familyId
          ..['createdAt'] = existing['createdAt']
          ..['updatedAt'] = existing['updatedAt'];
        await _messagesCollection(familyId, callId)
            .doc(id)
            .set(payload, SetOptions(merge: true));
        return;
      }
    }
    data['_pending'] = false;
    await box.put(_messageKey(callId, id), data);
  }

  Future<Map<String, dynamic>> _decode(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final decoded = await _encryption.decode(doc.data());
    decoded['id'] = doc.id;
    decoded['conversationId'] ??= doc.reference.parent.parent?.id;
    decoded['updatedAt'] ??= decoded['createdAt'] ??
        DateTime.now().toUtc().toIso8601String();
    return decoded;
  }

  String _boxName(String familyId) => 'call_messages_$familyId';

  String _deleteBoxName(String familyId) => 'call_messages_${familyId}__deletes';

  String _messageKey(String callId, String messageId) => '$callId::$messageId';

  String _listenerKey(String familyId, String callId) => '$familyId::$callId';
}

