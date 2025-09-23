import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/conversation.dart';
import '../models/event.dart';
import '../models/family_member.dart';
import '../models/friend.dart';
import '../models/gallery_item.dart';
import '../models/message.dart';
import '../models/pending_op.dart';
import '../models/schedule_item.dart';
import '../models/task.dart';
import 'encryption_service.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryption = encryptionService ?? EncryptionService();

  final FirebaseFirestore _firestore;
  final EncryptionService _encryption;

  static const String _pendingBoxName = 'pending_ops';

  String _membersCacheBox(String familyId) => 'cache_members_$familyId';
  String _tasksCacheBox(String familyId) => 'cache_tasks_$familyId';
  String _eventsCacheBox(String familyId) => 'cache_events_$familyId';
  String _scheduleCacheBox(String familyId) => 'cache_schedule_$familyId';
  String _friendsCacheBox(String familyId) => 'cache_friends_$familyId';
  String _galleryCacheBox(String familyId) => 'cache_gallery_$familyId';
  String _conversationsCacheBox(String familyId) =>
      'cache_conversations_$familyId';
  String _messagesCacheBox(String familyId, String conversationId) =>
      'cache_messages_${familyId}_$conversationId';

  CollectionReference<_EncryptedDoc> _familyCollection(
    String familyId,
    String collection,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection(collection)
        .withConverter<_EncryptedDoc>(
          fromFirestore: (snapshot, _) => _EncryptedDoc(
            snapshot.id,
            Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{}),
          ),
          toFirestore: (value, _) => value.raw,
        );
  }

  CollectionReference<_EncryptedDoc> _messageCollection(
    String familyId,
    String conversationId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .withConverter<_EncryptedDoc>(
          fromFirestore: (snapshot, _) => _EncryptedDoc(
            snapshot.id,
            Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{}),
          ),
          toFirestore: (value, _) => value.raw,
        );
  }

  Future<void> replayPendingOperations() async {
    final Box box = await _openBox(_pendingBoxName);
    final List<PendingOp> ops = box.values
        .whereType<Map>()
        .map((dynamic value) =>
            PendingOp.fromMap(Map<String, dynamic>.from(value as Map)))
        .toList()
      ..sort((PendingOp a, PendingOp b) => a.createdAt.compareTo(b.createdAt));

    for (final PendingOp op in ops) {
      try {
        if (op.action == PendingAction.delete) {
          await _deleteDocument(op.path, original: op);
        } else {
          await _setDocument(
            path: op.path,
            openData: op.openData ?? <String, dynamic>{},
            metadata: op.metadata,
            isNew: op.isNew,
            original: op,
          );
        }
      } on FirebaseException catch (error) {
        if (!_shouldQueue(error)) {
          rethrow;
        }
        break;
      }
    }
  }

  Future<List<FamilyMember>> loadCachedMembers(String familyId) =>
      _loadCachedList(_membersCacheBox(familyId), FamilyMember.fromDecodableMap);

  Future<List<Task>> loadCachedTasks(String familyId) =>
      _loadCachedList(_tasksCacheBox(familyId), Task.fromDecodableMap);

  Future<List<Event>> loadCachedEvents(String familyId) =>
      _loadCachedList(_eventsCacheBox(familyId), Event.fromDecodableMap);

  Future<List<ScheduleItem>> loadCachedSchedule(String familyId) =>
      _loadCachedList(_scheduleCacheBox(familyId), ScheduleItem.fromDecodableMap);

  Future<List<Friend>> loadCachedFriends(String familyId) =>
      _loadCachedList(_friendsCacheBox(familyId), Friend.fromDecodableMap);

  Future<List<GalleryItem>> loadCachedGallery(String familyId) =>
      _loadCachedList(_galleryCacheBox(familyId), GalleryItem.fromDecodableMap);

  Future<List<Conversation>> loadCachedConversations(String familyId) =>
      _loadCachedList(
        _conversationsCacheBox(familyId),
        (Map<String, dynamic> map) => Conversation.fromDecodableMap(
          map,
          id: (map['id'] ?? '').toString(),
          participantIds: (map['participantIds'] as List?)
                  ?.map((dynamic e) => e.toString())
                  .toList() ??
              const <String>[],
          createdAt: _toDateTime(map['createdAt']),
          updatedAt: _toDateTime(map['updatedAt']),
        ),
      );

  Future<List<Message>> loadCachedMessages(
    String familyId,
    String conversationId,
  ) =>
      _loadCachedList(
        _messagesCacheBox(familyId, conversationId),
        Message.fromCache,
      );

  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _familyCollection(familyId, 'members')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<FamilyMember> members = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return FamilyMember.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _membersCacheBox(familyId),
        members.map((FamilyMember member) => member.toLocalMap()).toList(),
      );
      return members;
    });
  }

  Future<void> createFamilyMember(String familyId, FamilyMember member) async {
    await _setDocument(
      path: _documentPath(familyId, 'members', member.id),
      openData: member.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> updateFamilyMember(String familyId, FamilyMember member) async {
    await _setDocument(
      path: _documentPath(familyId, 'members', member.id),
      openData: member.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: false,
    );
  }

  Future<void> deleteFamilyMember(String familyId, String memberId) async {
    await _deleteDocument(_documentPath(familyId, 'members', memberId));
  }

  Stream<List<Task>> watchTasks(String familyId) {
    return _familyCollection(familyId, 'tasks')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<Task> tasks = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return Task.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _tasksCacheBox(familyId),
        tasks.map((Task task) => task.toLocalMap()).toList(),
      );
      return tasks;
    });
  }

  Future<void> createTask(String familyId, Task task) async {
    await _setDocument(
      path: _documentPath(familyId, 'tasks', task.id),
      openData: task.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> updateTask(String familyId, Task task) async {
    await _setDocument(
      path: _documentPath(familyId, 'tasks', task.id),
      openData: task.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: false,
    );
  }

  Future<void> deleteTask(String familyId, String taskId) async {
    await _deleteDocument(_documentPath(familyId, 'tasks', taskId));
  }

  Stream<List<Event>> watchEvents(String familyId) {
    return _familyCollection(familyId, 'events')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<Event> events = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return Event.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _eventsCacheBox(familyId),
        events.map((Event event) => event.toLocalMap()).toList(),
      );
      return events;
    });
  }

  Future<void> createEvent(String familyId, Event event) async {
    await _setDocument(
      path: _documentPath(familyId, 'events', event.id),
      openData: event.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> updateEvent(String familyId, Event event) async {
    await _setDocument(
      path: _documentPath(familyId, 'events', event.id),
      openData: event.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: false,
    );
  }

  Future<void> deleteEvent(String familyId, String eventId) async {
    await _deleteDocument(_documentPath(familyId, 'events', eventId));
  }

  Stream<List<ScheduleItem>> watchSchedule(String familyId) {
    return _familyCollection(familyId, 'scheduleItems')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<ScheduleItem> items = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return ScheduleItem.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _scheduleCacheBox(familyId),
        items.map((ScheduleItem item) => item.toLocalMap()).toList(),
      );
      return items;
    });
  }

  Future<void> createScheduleItem(
    String familyId,
    ScheduleItem item,
  ) async {
    await _setDocument(
      path: _documentPath(familyId, 'scheduleItems', item.id),
      openData: item.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> deleteScheduleItem(String familyId, String itemId) async {
    await _deleteDocument(_documentPath(familyId, 'scheduleItems', itemId));
  }

  Stream<List<Friend>> watchFriends(String familyId) {
    return _familyCollection(familyId, 'friends')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<Friend> friends = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return Friend.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _friendsCacheBox(familyId),
        friends.map((Friend friend) => friend.toLocalMap()).toList(),
      );
      return friends;
    });
  }

  Future<void> upsertFriend(String familyId, Friend friend) async {
    await _setDocument(
      path: _documentPath(familyId, 'friends', friend.id),
      openData: friend.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> deleteFriend(String familyId, String friendId) async {
    await _deleteDocument(_documentPath(familyId, 'friends', friendId));
  }

  Stream<List<GalleryItem>> watchGallery(String familyId) {
    return _familyCollection(familyId, 'gallery')
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<GalleryItem> items = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          return GalleryItem.fromDecodableMap(<String, dynamic>{
            ...open,
            'id': doc.id,
            'createdAt': metadata['createdAt']?.toIso8601String(),
            'updatedAt': metadata['updatedAt']?.toIso8601String(),
          });
        },
      );
      await _cacheList(
        _galleryCacheBox(familyId),
        items.map((GalleryItem item) => item.toLocalMap()).toList(),
      );
      return items;
    });
  }

  Future<void> upsertGalleryItem(String familyId, GalleryItem item) async {
    await _setDocument(
      path: _documentPath(familyId, 'gallery', item.id),
      openData: item.toEncodableMap(),
      metadata: <String, dynamic>{},
      isNew: true,
    );
  }

  Future<void> deleteGalleryItem(String familyId, String itemId) async {
    await _deleteDocument(_documentPath(familyId, 'gallery', itemId));
  }

  Stream<List<Conversation>> watchConversations(String familyId) {
    return _familyCollection(familyId, 'conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<Conversation> conversations = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          final List<String> participants =
              (metadata['participantIds'] as List?)
                      ?.map((dynamic e) => e.toString())
                      .toList() ??
                  const <String>[];
          return Conversation.fromDecodableMap(
            open,
            id: doc.id,
            participantIds: participants,
            createdAt: metadata['createdAt'] as DateTime?,
            updatedAt: metadata['updatedAt'] as DateTime?,
          );
        },
      );
      await _cacheList(
        _conversationsCacheBox(familyId),
        conversations
            .map((Conversation conversation) => <String, dynamic>{
                  'id': conversation.id,
                  'participantIds': conversation.participantIds,
                  'title': conversation.title,
                  'avatarUrl': conversation.avatarUrl,
                  'lastMessagePreview': conversation.lastMessagePreview,
                  'createdAt': conversation.createdAt?.toIso8601String(),
                  'updatedAt': conversation.updatedAt?.toIso8601String(),
                })
            .toList(),
      );
      return conversations;
    });
  }

  Future<Conversation> createConversation({
    required String familyId,
    required Conversation conversation,
  }) async {
    await _setDocument(
      path: _documentPath(familyId, 'conversations', conversation.id),
      openData: conversation.toEncodableMap(),
      metadata: <String, dynamic>{
        'participantIds': conversation.participantIds,
      },
      isNew: true,
    );
    return conversation;
  }

  Future<void> updateConversation({
    required String familyId,
    required Conversation conversation,
  }) async {
    await _setDocument(
      path: _documentPath(familyId, 'conversations', conversation.id),
      openData: conversation.toEncodableMap(),
      metadata: <String, dynamic>{
        'participantIds': conversation.participantIds,
      },
      isNew: false,
    );
  }

  Future<void> deleteConversation(String familyId, String conversationId) async {
    await _deleteDocument(_documentPath(familyId, 'conversations', conversationId));
  }

  Stream<List<Message>> watchMessages({
    required String familyId,
    required String conversationId,
    int limit = 50,
  }) {
    return _messageCollection(familyId, conversationId)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .asyncMap((QuerySnapshot<_EncryptedDoc> snapshot) async {
      final List<Message> messages = await _decryptDocuments(
        docs: snapshot.docs,
        builder: (_EncryptedDoc doc, Map<String, dynamic> open,
            Map<String, dynamic> metadata) {
          final String ciphertext = (doc.raw['ciphertext'] ?? '').toString();
          final String iv = (doc.raw['iv'] ?? '').toString();
          final int version = doc.raw['encVersion'] is int
              ? doc.raw['encVersion'] as int
              : int.tryParse('${doc.raw['encVersion']}') ?? 0;
          return Message.fromDecodableMap(
            open,
            metadata: <String, dynamic>{
              'senderId': metadata['senderId'],
              'type': metadata['type'],
              'status': metadata['status'],
              'createdAt': metadata['createdAt'],
              'editedAt': metadata['editedAt'],
            },
            id: doc.id,
            conversationId: conversationId,
            ciphertext: ciphertext,
            iv: iv,
            encVersion: version,
          );
        },
      );
      await _cacheList(
        _messagesCacheBox(familyId, conversationId),
        messages.map((Message message) => message.toLocalMap()).toList(),
      );
      return messages;
    });
  }

  Future<Message> sendMessage({
    required String familyId,
    required String conversationId,
    required Message draft,
  }) async {
    final EncryptedBlob blob = await _encryption.encrypt(draft.toEncodableMap());
    final Map<String, dynamic> metadata = <String, dynamic>{
      'senderId': draft.senderId,
      'type': draft.type.name,
      'status': draft.status.name,
    };

    await _setDocument(
      path: _messagePath(familyId, conversationId, draft.id),
      openData: draft.toEncodableMap(),
      metadata: metadata,
      isNew: true,
      preEncrypted: blob,
    );

    await _firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> conversationRef =
          _firestore.doc(_documentPath(familyId, 'conversations', conversationId));
      final DocumentSnapshot<Map<String, dynamic>> snap =
          await tx.get(conversationRef);
      final Map<String, dynamic> raw =
          Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});
      final EncryptedBlob? existing = EncryptedBlob.fromFirestore(raw);
      final Map<String, dynamic> open = existing == null
          ? <String, dynamic>{}
          : await _encryption.decrypt(existing);
      open['lastMessagePreview'] = draft.text ?? _previewForType(draft.type);
      final EncryptedBlob updated = await _encryption.encrypt(open);
      final List<String> participants =
          (raw['participantIds'] as List?)?.map((dynamic e) => e.toString()).toList() ??
              <String>[];
      final Map<String, dynamic> update = <String, dynamic>{
        ...updated.toFirestoreMap(),
        'participantIds': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      tx.set(conversationRef, update, SetOptions(merge: true));
    });

    return draft.copyWith(
      ciphertext: base64Encode(blob.ciphertext),
      iv: base64Encode(blob.iv),
      encVersion: blob.version,
    );
  }

  Future<void> updateMessageStatus({
    required String familyId,
    required String conversationId,
    required Message message,
    required MessageStatus status,
  }) async {
    final Message updated = message.copyWith(status: status);
    await _setDocument(
      path: _messagePath(familyId, conversationId, message.id),
      openData: updated.toEncodableMap(),
      metadata: <String, dynamic>{
        'senderId': updated.senderId,
        'type': updated.type.name,
        'status': status.name,
      },
      isNew: false,
    );
  }

  Future<void> deleteMessage({
    required String familyId,
    required String conversationId,
    required String messageId,
  }) async {
    await _deleteDocument(_messagePath(familyId, conversationId, messageId));
  }

  Future<List<T>> _loadCachedList<T>(
    String boxName,
    T Function(Map<String, dynamic>) builder,
  ) async {
    final Box box = await _openBox(boxName);
    final List<dynamic>? raw = box.get('data') as List<dynamic>?;
    if (raw == null) {
      return <T>[];
    }
    return raw
        .whereType<Map>()
        .map((dynamic entry) =>
            builder(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  Future<void> _cacheList(String boxName, List<Map<String, dynamic>> data) async {
    final Box box = await _openBox(boxName);
    await box.put('data', data);
  }

  Future<Box> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return Hive.openBox(name);
  }

  Future<List<T>> _decryptDocuments<T>({
    required Iterable<QueryDocumentSnapshot<_EncryptedDoc>> docs,
    required T Function(
            _EncryptedDoc doc, Map<String, dynamic> open, Map<String, dynamic> metadata)
        builder,
  }) async {
    final List<T> result = <T>[];
    for (final QueryDocumentSnapshot<_EncryptedDoc> entry in docs) {
      final _EncryptedDoc doc = entry.data();
      final Map<String, dynamic> metadata = _metadata(doc);
      final EncryptedBlob? blob = EncryptedBlob.fromFirestore(doc.raw);
      Map<String, dynamic> open = <String, dynamic>{};
      if (blob != null) {
        open = await _encryption.decrypt(blob);
      }
      result.add(builder(doc, open, metadata));
    }
    return result;
  }

  Map<String, dynamic> _metadata(_EncryptedDoc doc) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(doc.raw);
    copy.remove('ciphertext');
    copy.remove('iv');
    copy.remove('encVersion');
    copy['createdAt'] = _toDateTime(copy['createdAt']);
    copy['updatedAt'] = _toDateTime(copy['updatedAt']);
    return copy;
  }

  String _documentPath(String familyId, String collection, String documentId) =>
      'families/$familyId/$collection/$documentId';

  String _messagePath(
    String familyId,
    String conversationId,
    String messageId,
  ) =>
      'families/$familyId/conversations/$conversationId/messages/$messageId';

  Future<void> _setDocument({
    required String path,
    required Map<String, dynamic> openData,
    required Map<String, dynamic>? metadata,
    required bool isNew,
    PendingOp? original,
    EncryptedBlob? preEncrypted,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _firestore.doc(path);
    final EncryptedBlob blob =
        preEncrypted ?? await _encryption.encrypt(openData);
    final Map<String, dynamic> payload = <String, dynamic>{
      ...blob.toFirestoreMap(),
      if (metadata != null) ...metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    try {
      await ref.set(payload, SetOptions(merge: true));
      if (original != null) {
        await _removePending(original.id);
      }
    } on FirebaseException catch (error) {
      if (_shouldQueue(error) && original == null) {
        await _savePending(
          PendingOp.upsert(
            path: path,
            openData: openData,
            metadata: metadata,
            isNew: isNew,
          ),
        );
      } else if (!_shouldQueue(error)) {
        rethrow;
      }
    }
  }

  Future<void> _deleteDocument(String path, {PendingOp? original}) async {
    final DocumentReference<Map<String, dynamic>> ref = _firestore.doc(path);
    try {
      await ref.delete();
      if (original != null) {
        await _removePending(original.id);
      }
    } on FirebaseException catch (error) {
      if (_shouldQueue(error) && original == null) {
        await _savePending(PendingOp.delete(path: path));
      } else if (!_shouldQueue(error)) {
        rethrow;
      }
    }
  }

  Future<void> _savePending(PendingOp op) async {
    final Box box = await _openBox(_pendingBoxName);
    await box.put(op.id, op.toMap());
  }

  Future<void> _removePending(String id) async {
    final Box box = await _openBox(_pendingBoxName);
    await box.delete(id);
  }

  bool _shouldQueue(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'network-request-failed' ||
        error.code == 'failed-precondition';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _previewForType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 Attachment';
      case MessageType.text:
      default:
        return 'Message';
    }
  }
}

class _EncryptedDoc {
  _EncryptedDoc(this.id, this.raw);

  final String id;
  final Map<String, dynamic> raw;
}
