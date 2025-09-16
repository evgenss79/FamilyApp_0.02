import 'package:family_app_flutter/providers/family_data.dart';
import 'package:family_app_flutter/providers/chat_data.dart';
import 'package:family_app_flutter/providers/schedule_data.dart';
import 'package:family_app_flutter/services/firestore_service.dart';
import 'package:family_app_flutter/security/encrypted_firestore_service.dart';

/// A service responsible for synchronizing local providers with remote
/// Firestore. This service uploads all local data to Firestore and
/// downloads remote data to update providers. Data is encrypted
/// before it is written using [EncryptedFirestoreService].
class DataSyncService {
  final FamilyDataV001 familyData;
  final ChatDataV001 chatData;
  final ScheduleDataV001 scheduleData;
  final FirestoreService _firestoreService;
  final EncryptedFirestoreService _encryptedFirestoreService;

  DataSyncService({
    required this.familyData,
    required this.chatData,
    required this.scheduleData,
    FirestoreService? firestoreService,
    EncryptedFirestoreService? encryptedFirestoreService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _encryptedFirestoreService = encryptedFirestoreService ??
            EncryptedFirestoreService();

  /// Uploads all local data to Firestore. This should be called after
  /// local providers have been populated from Hive. It iterates over
  /// family members, tasks, events and schedule items and writes
  /// them to Firestore using the appropriate service. For chats it
  /// uploads conversations and messages via ChatDataV001.
  Future<void> uploadAll(String familyId) async {
    // Upload family members using encrypted service
    for (final member in familyData.members) {
      await _encryptedFirestoreService.upsertFamilyMember(
        familyId: familyId,
        memberId: member.id,
        memberData: member.toMap(),
      );
    }
    // Upload tasks and events (unencrypted for now)
    await _firestoreService.saveTasks(familyId, familyData.tasks);
    await _firestoreService.saveEvents(familyId, familyData.events);
    // Upload schedule items
    await _firestoreService.saveScheduleItems(familyId, scheduleData.items);
    // Upload chat conversations and messages
    await _firestoreService.saveConversations(familyId, chatData.conversations);
    await _firestoreService.saveMessages(familyId, chatData.messages);
  }

  /// Downloads all remote data from Firestore and populates the
  /// providers. This should be called after Firebase has been
  /// initialized. It overwrites local data with the latest values
  /// from Firestore. Decryption is handled automatically by
  /// [EncryptedFirestoreService] where necessary.
  Future<void> downloadAll(String familyId) async {
    // Download members and set to provider
    final members = await _firestoreService.fetchFamilyMembers(familyId);
    familyData.setMembers(members);
    // Download tasks and events
    final tasks = await _firestoreService.fetchTasks(familyId);
    familyData.setTasks(tasks);
    final events = await _firestoreService.fetchEvents(familyId);
    familyData.setEvents(events);
    // Download schedule items
    final scheduleItems = await _firestoreService.fetchScheduleItems(familyId);
    scheduleData.setItems(scheduleItems);
    // Download conversations and messages
    final conversations = await _firestoreService.fetchConversations(familyId);
    chatData.setConversations(conversations);
    final messages = await _firestoreService.fetchMessages(familyId);
    chatData.setMessages(messages);
  }
}