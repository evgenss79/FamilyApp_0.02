import 'package:family_app_flutter/providers/family_data.dart';
import 'package:family_app_flutter/providers/chat_data.dart';
import 'package:family_app_flutter/providers/schedule_data.dart';

import '../models/task.dart';
import '../models/event.dart';
import '../models/schedule_item.dart';

import '../services/firestore_service.dart';
import '../security/encrypted_firestore_service.dart';

/// A service responsible for synchronizing local providers with remote Firestore.
/// This service uploads all local data to Firestore and downloads remote data to update providers.
/// Data is encrypted for family members using [EncryptedFirestoreService]. For chats it delegates save/load
/// to [ChatDataV001] which groups messages by conversation. Schedule items are also supported.
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
        _encryptedFirestoreService =
            encryptedFirestoreService ?? EncryptedFirestoreService();

  /// Uploads all local data to Firestore. This should be called after local providers have been populated from Hive.
  /// It uploads family members (encrypted), tasks, events, schedule items, and chats. Then delegates chat sync to
  /// [ChatDataV001.saveToFirestore].
  Future<void> uploadAll(String familyId) async {
    // Upload family members using encrypted service
    for (final member in familyData.members) {
      await _encryptedFirestoreService.upsertFamilyMember(
        familyId: familyId,
        memberId: member.id,
        memberData: member.toMap(),
      );
    }
    // Upload tasks, events and schedule items
    await _firestoreService.saveTasks(familyId, familyData.tasks);
    await _firestoreService.saveEvents(familyId, familyData.events);
    await _firestoreService.saveScheduleItems(familyId, scheduleData.items);
    // Upload chats
    chatData.familyId = familyId;
    await chatData.saveToFirestore();
  }

  /// Downloads all remote data from Firestore and populates the providers.
  /// Uses [updatedAt] timestamps to resolve conflicts: if a record exists both locally and remotely,
  /// the version with the later updatedAt is kept. After merging, the consolidated data is saved
  /// back to Firestore to propagate the latest version.
  Future<void> downloadAll(String familyId) async {
    // Download members
    final members = await _firestoreService.fetchFamilyMembers(familyId);
    familyData.setMembers(members);

    // Download remote lists
    final remoteTasks = await _firestoreService.fetchTasks(familyId);
    final remoteEvents = await _firestoreService.fetchEvents(familyId);
    final remoteSchedule = await _firestoreService.fetchScheduleItems(familyId);

    // Merge tasks
    final localTasksMap = {for (final t in familyData.tasks) t.id: t};
    final remoteTasksMap = {for (final t in remoteTasks) t.id: t};
    final taskIds = {...localTasksMap.keys, ...remoteTasksMap.keys};
    final mergedTasks = <Task>[];
    for (final id in taskIds) {
      final local = localTasksMap[id];
      final remote = remoteTasksMap[id];
      if (local != null && remote != null) {
        mergedTasks.add(local.updatedAt.isAfter(remote.updatedAt) ? local : remote);
      } else if (local != null) {
        mergedTasks.add(local);
      } else if (remote != null) {
        mergedTasks.add(remote);
      }
    }

    // Merge events
    final localEventsMap = {for (final e in familyData.events) e.id: e};
    final remoteEventsMap = {for (final e in remoteEvents) e.id: e};
    final eventIds = {...localEventsMap.keys, ...remoteEventsMap.keys};
    final mergedEvents = <Event>[];
    for (final id in eventIds) {
      final local = localEventsMap[id];
      final remote = remoteEventsMap[id];
      if (local != null && remote != null) {
        mergedEvents.add(local.updatedAt.isAfter(remote.updatedAt) ? local : remote);
      } else if (local != null) {
        mergedEvents.add(local);
      } else if (remote != null) {
        mergedEvents.add(remote);
      }
    }

    // Merge schedule items
    final localScheduleMap = {for (final s in scheduleData.items) s.id: s};
    final remoteScheduleMap = {for (final s in remoteSchedule) s.id: s};
    final scheduleIds = {...localScheduleMap.keys, ...remoteScheduleMap.keys};
    final mergedSchedule = <ScheduleItem>[];
    for (final id in scheduleIds) {
      final local = localScheduleMap[id];
      final remote = remoteScheduleMap[id];
      if (local != null && remote != null) {
        mergedSchedule
            .add(local.updatedAt.isAfter(remote.updatedAt) ? local : remote);
      } else if (local != null) {
        mergedSchedule.add(local);
      } else if (remote != null) {
        mergedSchedule.add(remote);
      }
    }

    // Save merged data back to providers
    familyData.setTasks(mergedTasks);
    familyData.setEvents(mergedEvents);
    scheduleData.setItems(mergedSchedule);

    // Save merged data back to Firestore
    await _firestoreService.saveTasks(familyId, mergedTasks);
    await _firestoreService.saveEvents(familyId, mergedEvents);
    await _firestoreService.saveScheduleItems(familyId, mergedSchedule);

    // Download chats
    chatData.familyId = familyId;
    await chatData.loadFromFirestore();
  }
}
