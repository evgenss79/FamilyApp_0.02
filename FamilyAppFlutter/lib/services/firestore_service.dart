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
    return _firestore.collection('families').doc(familyId).collection(collection);
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
    final snapshot = await _collection(familyId, 'chats')
        .doc(chatId)
        .collection('messages')
        .get();
    final messages = <ChatMessage>[];
    for (final doc in snapshot.docs) {
      messages.add(ChatMessage.fromMap(await _decodedMap(doc)));
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> upsertChatMessage(
    String familyId,
    String chatId,
    ChatMessage message,
  ) async {
    await _enc.setEncrypted(
      ref: _collection(familyId, 'chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id),
      data: message.toMap(),
    );
  }

  Future<void> deleteChatMessages(String familyId, String chatId) async {
    final coll =
        _collection(familyId, 'chats').doc(chatId).collection('messages');
    final snapshot = await coll.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
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

  Future<void> deleteConversation(String familyId, String conversationId) async {
    await _collection(familyId, 'conversations').doc(conversationId).delete();
  }

  Future<List<Message>> fetchCallMessages(
    String familyId,
    String conversationId,
  ) async {
    final coll = _collection(familyId, 'conversations')
        .doc(conversationId)
        .collection('messages');
    final snapshot = await coll.get();
    final messages = <Message>[];
    for (final doc in snapshot.docs) {
      messages.add(Message.fromMap(await _decodedMap(doc)));
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
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

  Future<void> deleteCallMessages(
    String familyId,
    String conversationId,
  ) async {
    final coll = _collection(familyId, 'conversations')
        .doc(conversationId)
        .collection('messages');
    final snapshot = await coll.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
