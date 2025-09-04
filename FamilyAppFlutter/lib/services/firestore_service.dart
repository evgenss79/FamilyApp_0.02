import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch family members from Firestore for a given family id.
  Future<List<FamilyMember>> fetchFamilyMembers(String familyId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
    return snapshot.docs
        .map((doc) => FamilyMember.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList();
  }

  /// Save the list of family members to Firestore.
  Future<void> saveFamilyMembers(String familyId, List<FamilyMember> members) async {
    final collectionRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('members');
    final batch = _firestore.batch();
    for (final member in members) {
      final docRef = collectionRef.doc(member.id);
      batch.set(docRef, member.toMap());
    }
    await batch.commit();
  }

  /// Fetch tasks for a family.
  Future<List<Task>> fetchTasks(String familyId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .get();
    return snapshot.docs
        .map((doc) => Task.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList();
  }

  /// Save tasks to Firestore.
  Future<void> saveTasks(String familyId, List<Task> tasks) async {
    final collectionRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks');
    final batch = _firestore.batch();
    for (final task in tasks) {
      final docRef = collectionRef.doc(task.id);
      batch.set(docRef, task.toMap());
    }
    await batch.commit();
  }

  /// Fetch events for a family.
  Future<List<Event>> fetchEvents(String familyId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .get();
    return snapshot.docs
        .map((doc) => Event.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList();
  }

  /// Save events to Firestore.
  Future<void> saveEvents(String familyId, List<Event> events) async {
    final collectionRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('events');
    final batch = _firestore.batch();
    for (final event in events) {
      final docRef = collectionRef.doc(event.id);
      batch.set(docRef, event.toMap());
    }
    await batch.commit();
  }

  /// Fetch conversations for a family.
  Future<List<Conversation>> fetchConversations(String familyId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .get();
    return snapshot.docs
        .map((doc) => Conversation.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList();
  }

  /// Save conversations to Firestore.
  Future<void> saveConversations(String familyId, List<Conversation> conversations) async {
    final collectionRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations');
    final batch = _firestore.batch();
    for (final conversation in conversations) {
      final docRef = collectionRef.doc(conversation.id);
      batch.set(docRef, conversation.toMap());
    }
    await batch.commit();
  }

  /// Fetch messages for a conversation.
  Future<List<Message>> fetchMessages(String familyId, String conversationId) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
    return snapshot.docs
        .map((doc) => Message.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList();
  }

  /// Save messages for a conversation.
  Future<void> saveMessages(String familyId, String conversationId, List<Message> messages) async {
    final collectionRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');
    final batch = _firestore.batch();
    for (final message in messages) {
      final docRef = collectionRef.doc(message.id);
      batch.set(docRef, message.toMap());
    }
    await batch.commit();
  }
}
