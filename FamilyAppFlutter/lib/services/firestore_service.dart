import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/schedule_item.dart';
import '../security/encrypted_firestore_service.dart';

/// Service wrapping common Firestore operations for the app.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptedFirestoreService _enc = const EncryptedFirestoreService();

  /// --------- FAMILY MEMBERS (encrypted upsert in DataSyncService) ----------
  Future<List<FamilyMember>> fetchFamilyMembers(String familyId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
    return snapshot.docs
        .map((doc) => FamilyMember.fromMap(
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  Future<void> saveFamilyMembers(
      String familyId, List<FamilyMember> members) async {
    final collectionRef =
        _firestore.collection('families').doc(familyId).collection('members');
    final batch = _firestore.batch();
    for (final member in members) {
      final docRef = collectionRef.doc(member.id);
      batch.set(docRef, member.toMap());
    }
    await batch.commit();
  }

  /// ------------------------------ TASKS -------------------------------------
  Future<List<Task>> fetchTasks(String familyId) async {
    final coll =
        _firestore.collection('families').doc(familyId).collection('tasks');
    final snapshot = await coll.get();

    final List<Task> out = [];
    for (final doc in snapshot.docs) {
      final decrypted = await _enc.getDecrypted(ref: coll.doc(doc.id));
      final data =
          decrypted.isEmpty ? Map<String, dynamic>.from(doc.data()) : decrypted;
      out.add(Task.fromMap(data));
    }
    return out;
  }

  Future<void> saveTasks(String familyId, List<Task> tasks) async {
    final coll =
        _firestore.collection('families').doc(familyId).collection('tasks');
    for (final task in tasks) {
      final ref = coll.doc(task.id);
      await _enc.setEncrypted(ref: ref, data: task.toMap());
    }
  }

  /// ------------------------------ EVENTS ------------------------------------
  Future<List<Event>> fetchEvents(String familyId) async {
    final coll =
        _firestore.collection('families').doc(familyId).collection('events');
    final snapshot = await coll.get();

    final List<Event> out = [];
    for (final doc in snapshot.docs) {
      final decrypted = await _enc.getDecrypted(ref: coll.doc(doc.id));
      final data =
          decrypted.isEmpty ? Map<String, dynamic>.from(doc.data()) : decrypted;
      out.add(Event.fromMap(data));
    }
    return out;
  }

  Future<void> saveEvents(String familyId, List<Event> events) async {
    final coll =
        _firestore.collection('families').doc(familyId).collection('events');
    for (final e in events) {
      final ref = coll.doc(e.id);
      await _enc.setEncrypted(ref: ref, data: e.toMap());
    }
  }

  /// --------------------------- SCHEDULE ITEMS -------------------------------
  Future<List<ScheduleItem>> fetchScheduleItems(String familyId) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('scheduleItems');
    final snapshot = await coll.get();

    final List<ScheduleItem> out = [];
    for (final doc in snapshot.docs) {
      final decrypted = await _enc.getDecrypted(ref: coll.doc(doc.id));
      final data =
          decrypted.isEmpty ? Map<String, dynamic>.from(doc.data()) : decrypted;
      out.add(ScheduleItem.fromMap(data));
    }
    return out;
  }

  Future<void> saveScheduleItems(
      String familyId, List<ScheduleItem> items) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('scheduleItems');
    for (final it in items) {
      final ref = coll.doc(it.id);
      await _enc.setEncrypted(ref: ref, data: it.toMap());
    }
  }

  /// ------------------------------ CHATS -------------------------------------

  Future<List<Conversation>> fetchConversations(String familyId) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations');
    final snapshot = await coll.get();

    final List<Conversation> out = [];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      out.add(Conversation.fromMap(data));
    }
    return out;
  }

  Future<void> saveConversations(
      String familyId, List<Conversation> conversations) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations');
    for (final c in conversations) {
      await coll.doc(c.id).set(c.toMap());
    }
  }

  Future<List<Message>> fetchMessages(
      String familyId, String conversationId) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final snapshot = await coll.orderBy('timestamp').get();

    final List<Message> out = [];
    for (final doc in snapshot.docs) {
      final decrypted = await _enc.getDecrypted(ref: coll.doc(doc.id));
      final data =
          decrypted.isEmpty ? Map<String, dynamic>.from(doc.data()) : decrypted;
      out.add(Message.fromMap(data));
    }
    return out;
  }

  Future<void> saveMessages(
      String familyId, String conversationId, List<Message> messages) async {
    final coll = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    for (final m in messages) {
      final ref = coll.doc(m.id);
      await _enc.setEncrypted(ref: ref, data: m.toMap());
    }
  }
}
