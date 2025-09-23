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

/// Service wrapping common Firestore operations for the app.  All data is
/// written through [EncryptedFirestoreService] to keep the payload private.
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    EncryptedFirestoreService? encryption,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryption = encryption ?? const EncryptedFirestoreService();

  final FirebaseFirestore _firestore;
  final EncryptedFirestoreService _encryption;

  CollectionReference<Map<String, dynamic>> _collection(
    String familyId,
    String collection,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection(collection);
  }

  Future<Map<String, dynamic>> _decodeSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    Map<String, dynamic>? extras,
  }) async {
    final Map<String, dynamic> decrypted =
        await _encryption.decode(snapshot.data());
    final Map<String, dynamic> result = decrypted.isEmpty
        ? Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{})
        : Map<String, dynamic>.from(decrypted);
    result.remove('enc');
    result['id'] = snapshot.id;
    if (extras != null) {
      result.addAll(extras);
    }
    return result;
  }

  // ------------------------------ MEMBERS ----------------------------------
  Future<List<FamilyMember>> fetchFamilyMembers(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'members').get();
    final List<FamilyMember> members = <FamilyMember>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      members.add(FamilyMember.fromMap(await _decodeSnapshot(doc)));
    }
    return members;
  }

  Future<void> upsertFamilyMember(
    String familyId,
    FamilyMember member,
  ) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'members').doc(member.id),
      data: member.toMap(),
    );
  }

  Future<void> updateFamilyMember(
    String familyId,
    FamilyMember member,
  ) => upsertFamilyMember(familyId, member);

  Future<void> deleteFamilyMember(String familyId, String memberId) async {
    await _collection(familyId, 'members').doc(memberId).delete();
  }

  // -------------------------------- TASKS ----------------------------------
  Future<List<Task>> fetchTasks(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'tasks').get();
    final List<Task> tasks = <Task>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      tasks.add(Task.fromMap(await _decodeSnapshot(doc)));
    }
    tasks.sort((Task a, Task b) {
      final DateTime aDue = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDue = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDue.compareTo(bDue);
    });
    return tasks;
  }

  Future<void> upsertTask(String familyId, Task task) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'tasks').doc(task.id),
      data: task.toMap(),
    );
  }

  Future<void> updateTask(String familyId, Task task) =>
      upsertTask(familyId, task);

  Future<void> deleteTask(String familyId, String taskId) async {
    await _collection(familyId, 'tasks').doc(taskId).delete();
  }

  // ------------------------------- EVENTS ----------------------------------
  Future<List<Event>> fetchEvents(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'events').get();
    final List<Event> events = <Event>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      events.add(Event.fromMap(await _decodeSnapshot(doc)));
    }
    events.sort((Event a, Event b) => a.startDateTime.compareTo(b.startDateTime));
    return events;
  }

  Future<void> upsertEvent(String familyId, Event event) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'events').doc(event.id),
      data: event.toMap(),
    );
  }

  Future<void> deleteEvent(String familyId, String eventId) async {
    await _collection(familyId, 'events').doc(eventId).delete();
  }

  // -------------------------- SCHEDULE ITEMS -------------------------------
  Future<List<ScheduleItem>> fetchScheduleItems(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'scheduleItems').get();
    final List<ScheduleItem> items = <ScheduleItem>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      items.add(ScheduleItem.fromMap(await _decodeSnapshot(doc)));
    }
    items.sort((ScheduleItem a, ScheduleItem b) =>
        a.dateTime.compareTo(b.dateTime));
    return items;
  }

  Future<void> upsertScheduleItem(String familyId, ScheduleItem item) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'scheduleItems').doc(item.id),
      data: item.toMap(),
    );
  }

  Future<void> deleteScheduleItem(String familyId, String itemId) async {
    await _collection(familyId, 'scheduleItems').doc(itemId).delete();
  }

  // ------------------------------- FRIENDS ---------------------------------
  Future<List<Friend>> fetchFriends(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'friends').get();
    final List<Friend> friends = <Friend>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      friends.add(Friend.fromMap(await _decodeSnapshot(doc)));
    }
    friends.sort((Friend a, Friend b) => a.name.compareTo(b.name));
    return friends;
  }

  Future<void> upsertFriend(String familyId, Friend friend) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'friends').doc(friend.id),
      data: friend.toMap(),
    );
  }

  Future<void> deleteFriend(String familyId, String friendId) async {
    await _collection(familyId, 'friends').doc(friendId).delete();
  }

  // ------------------------------- GALLERY ---------------------------------
  Future<List<GalleryItem>> fetchGalleryItems(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'gallery').get();
    final List<GalleryItem> items = <GalleryItem>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      items.add(GalleryItem.fromMap(await _decodeSnapshot(doc)));
    }
    return items;
  }

  Future<void> upsertGalleryItem(String familyId, GalleryItem item) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'gallery').doc(item.id),
      data: item.toMap(),
    );
  }

  Future<void> deleteGalleryItem(String familyId, String itemId) async {
    await _collection(familyId, 'gallery').doc(itemId).delete();
  }

  // -------------------------------- CHATS ----------------------------------
  Future<List<Chat>> fetchChats(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'chats').get();
    final List<Chat> chats = <Chat>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      chats.add(Chat.fromMap(await _decodeSnapshot(doc)));
    }
    chats.sort((Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  Future<void> upsertChat(String familyId, Chat chat) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'chats').doc(chat.id),
      data: chat.toMap(),
    );
  }

  Future<void> deleteChat(String familyId, String chatId) async {
    await _deleteSubcollection(
      _collection(familyId, 'chats').doc(chatId).collection('messages'),
    );
    await _collection(familyId, 'chats').doc(chatId).delete();
  }

  Future<List<ChatMessage>> fetchChatMessages(
    String familyId,
    String chatId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(familyId, 'chats')
        .doc(chatId)
        .collection('messages')
        .get();
    final List<ChatMessage> messages = <ChatMessage>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data =
          await _decodeSnapshot(doc, extras: <String, dynamic>{'chatId': chatId});
      messages.add(ChatMessage.fromMap(data));
    }
    messages.sort((ChatMessage a, ChatMessage b) =>
        a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> upsertChatMessage(
    String familyId,
    String chatId,
    ChatMessage message,
  ) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id),
      data: message.toMap(),
    );
  }

  Future<void> deleteChatMessages(String familyId, String chatId) async {
    await _deleteSubcollection(
      _collection(familyId, 'chats').doc(chatId).collection('messages'),
    );
  }

  // ---------------------------- CALL CONVERSATIONS -------------------------
  Future<List<Conversation>> fetchConversations(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(familyId, 'conversations').get();
    final List<Conversation> conversations = <Conversation>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      conversations.add(Conversation.fromMap(await _decodeSnapshot(doc)));
    }
    conversations.sort((Conversation a, Conversation b) =>
        b.createdAt.compareTo(a.createdAt));
    return conversations;
  }

  Future<void> upsertConversation(
    String familyId,
    Conversation conversation,
  ) async {
    await _encryption.setEncrypted(
      ref: _collection(familyId, 'conversations').doc(conversation.id),
      data: conversation.toMap(),
    );
  }

  Future<void> deleteConversation(
    String familyId,
    String conversationId,
  ) async {
    await _deleteSubcollection(
      _collection(familyId, 'conversations')
          .doc(conversationId)
          .collection('messages'),
    );
    await _collection(familyId, 'conversations').doc(conversationId).delete();
  }

  Future<List<Message>> fetchCallMessages(
    String familyId,
    String conversationId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(familyId, 'conversations')
        .doc(conversationId)
        .collection('messages')
        .get();
    final List<Message> messages = <Message>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = await _decodeSnapshot(
        doc,
        extras: <String, dynamic>{
          'conversationId': conversationId,
        },
      );
      messages.add(Message.fromMap(data));
    }
    messages.sort((Message a, Message b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> upsertCallMessage(
    String familyId,
    String conversationId,
    Message message,
  ) async {
    await _encryption.setEncrypted(
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
    await _deleteSubcollection(
      _collection(familyId, 'conversations')
          .doc(conversationId)
          .collection('messages'),
    );
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> reference,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await reference.get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
