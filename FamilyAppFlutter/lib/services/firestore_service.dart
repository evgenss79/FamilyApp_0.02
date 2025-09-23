import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/event.dart';
import '../models/family_member.dart';
import '../models/friend.dart';
import '../models/gallery_item.dart';
import '../models/message.dart';
import '../models/schedule_item.dart';
import '../models/task.dart';
import '../security/encrypted_firestore_service.dart';

/// Service wrapping common Firestore operations for the app.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptedFirestoreService _enc = const EncryptedFirestoreService();

  CollectionReference<Map<String, dynamic>> _collection(
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
    final Box<Object?> box = await _openBox(_pendingBoxName);
    final List<PendingOp> ops = box.values
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> value) =>
            PendingOp.fromMap(Map<String, dynamic>.from(value)))
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

  Future<Map<String, dynamic>> _decodedMap(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> raw = await _enc.decode(doc.data());
    final Map<String, dynamic> map = raw.isEmpty
        ? Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{})
        : Map<String, dynamic>.from(raw);
    map.putIfAbsent('id', () => doc.id);
    return map;
  }

  // ------------------------------ MEMBERS ----------------------------------
  Future<List<FamilyMember>> fetchFamilyMembers(String familyId) async {
    final snapshot = await _collection(familyId, 'members').get();
    return [
      for (final doc in snapshot.docs) FamilyMember.fromMap(await _decodedMap(doc)),
    ];
  }

  Future<void> upsertFamilyMember(
    String familyId,
    FamilyMember member,
  ) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'members').doc(member.id),
      data: member.toMap(),
    );
  }

  Future<void> deleteFamilyMember(String familyId, String memberId) async {
    await _collection(familyId, 'members').doc(memberId).delete();
  }

  // -------------------------------- TASKS ----------------------------------
  Future<List<Task>> fetchTasks(String familyId) async {
    final snapshot = await _collection(familyId, 'tasks').get();
    final tasks = <Task>[];
    for (final doc in snapshot.docs) {
      tasks.add(Task.fromMap(await _decodedMap(doc)));
    }
    tasks.sort((a, b) {
      final aDue = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDue = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDue.compareTo(bDue);
    });
    return tasks;
  }

  Future<void> upsertTask(String familyId, Task task) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'tasks').doc(task.id),
      data: task.toMap(),
    );
  }

  Future<void> deleteTask(String familyId, String taskId) async {
    await _collection(familyId, 'tasks').doc(taskId).delete();
  }

  // ------------------------------- EVENTS ----------------------------------
  Future<List<Event>> fetchEvents(String familyId) async {
    final snapshot = await _collection(familyId, 'events').get();
    final events = <Event>[];
    for (final doc in snapshot.docs) {
      events.add(Event.fromMap(await _decodedMap(doc)));
    }
    events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return events;
  }

  Future<void> upsertEvent(String familyId, Event event) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'events').doc(event.id),
      data: event.toMap(),
    );
  }

  Future<void> deleteEvent(String familyId, String eventId) async {
    await _collection(familyId, 'events').doc(eventId).delete();
  }

  // -------------------------- SCHEDULE ITEMS -------------------------------
  Future<List<ScheduleItem>> fetchScheduleItems(String familyId) async {
    final snapshot = await _collection(familyId, 'scheduleItems').get();
    final items = <ScheduleItem>[];
    for (final doc in snapshot.docs) {
      items.add(ScheduleItem.fromMap(await _decodedMap(doc)));
    }
    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return items;
  }

  Future<void> upsertScheduleItem(String familyId, ScheduleItem item) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'scheduleItems').doc(item.id),
      data: item.toMap(),
    );
  }

  Future<void> deleteScheduleItem(String familyId, String itemId) async {
    await _collection(familyId, 'scheduleItems').doc(itemId).delete();
  }

  // ------------------------------- FRIENDS ---------------------------------
  Future<List<Friend>> fetchFriends(String familyId) async {
    final snapshot = await _collection(familyId, 'friends').get();
    return [
      for (final doc in snapshot.docs) Friend.fromMap(await _decodedMap(doc)),
    ];
  }

  Future<void> upsertFriend(String familyId, Friend friend) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'friends').doc(friend.id),
      data: friend.toMap(),
    );
  }

  Future<void> deleteFriend(String familyId, String friendId) async {
    await _collection(familyId, 'friends').doc(friendId).delete();
  }

  // ------------------------------- GALLERY ---------------------------------
  Future<List<GalleryItem>> fetchGalleryItems(String familyId) async {
    final snapshot = await _collection(familyId, 'gallery').get();
    return [
      for (final doc in snapshot.docs) GalleryItem.fromMap(await _decodedMap(doc)),
    ];
  }

  Future<void> upsertGalleryItem(String familyId, GalleryItem item) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'gallery').doc(item.id),
      data: item.toMap(),
    );
  }

  Future<void> deleteGalleryItem(String familyId, String itemId) async {
    await _collection(familyId, 'gallery').doc(itemId).delete();
  }

  // -------------------------------- CHATS ----------------------------------
  Future<List<Chat>> fetchChats(String familyId) async {
    final snapshot = await _collection(familyId, 'chats').get();
    final chats = <Chat>[];
    for (final doc in snapshot.docs) {
      chats.add(Chat.fromMap(await _decodedMap(doc)));
    }
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  Future<void> upsertChat(String familyId, Chat chat) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'chats').doc(chat.id),
      data: chat.toMap(),
    );
  }

  Future<void> deleteChat(String familyId, String chatId) async {
    await _collection(familyId, 'chats').doc(chatId).delete();
  }

  Future<List<ChatMessage>> fetchChatMessages(
    String familyId,
    String chatId,
  ) async {

    final Box<Object?> box = await _openBox(boxName);
    final List<Object?>? raw = box.get('data') as List<Object?>?;
    if (raw == null) {
      return <T>[];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> entry) =>
            builder(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> _cacheList(String boxName, List<Map<String, dynamic>> data) async {
    final Box<Object?> box = await _openBox(boxName);
    await box.put('data', data);
  }

  Future<Box<Object?>> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<Object?>(name);
    }
    return Hive.openBox<Object?>(name);
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

  // ---------------------------- CALL CONVERSATIONS -------------------------
  Future<List<Conversation>> fetchConversations(String familyId) async {
    final snapshot = await _collection(familyId, 'conversations').get();
    return [
      for (final doc in snapshot.docs)
        Conversation.fromMap(await _decodedMap(doc)),
    ];
  }

  Future<void> upsertConversation(
    String familyId,
    Conversation conversation,
  ) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'conversations').doc(conversation.id),
      data: conversation.toMap(),
    );
  }

  Future<void> _savePending(PendingOp op) async {
    final Box<Object?> box = await _openBox(_pendingBoxName);
    await box.put(op.id, op.toMap());
  }

  Future<void> _removePending(String id) async {
    final Box<Object?> box = await _openBox(_pendingBoxName);
    await box.delete(id);
  }

  Future<void> upsertCallMessage(
    String familyId,
    String conversationId,
    Message message,
  ) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id),
      data: message.toMap(),
    );
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
        return 'Message';
    }
  }
}
