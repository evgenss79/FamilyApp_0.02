import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../security/encrypted_firestore_service.dart';

/// Provider that holds all data about family members, tasks and events.
///
/// It exposes methods to load and save data from local storage and Firestore,
/// as well as CRUD operations. Additional `set*` methods allow replacing the
/// entire lists when downloading from the cloud.
class FamilyDataV001 extends ChangeNotifier {
  final List<FamilyMember> _members = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];

  final FirestoreService _firestoreService = FirestoreService();
  final EncryptedFirestoreService _encryptedFirestoreService =
      EncryptedFirestoreService();

  String? familyId;

  List<FamilyMember> get members => _members;
  List<Task> get tasks => _tasks;
  List<Event> get events => _events;

  Future<void> initialize(String fid) async {
    if (familyId == fid) return;
    familyId = fid;
    await loadFromStorage();
    await loadFromFirestore();
  }

  Future<void> loadFromStorage() async {
    _members
      ..clear()
      ..addAll(StorageServiceV001.loadMembers());
    _tasks
      ..clear()
      ..addAll(StorageServiceV001.loadTasks());
    _events
      ..clear()
      ..addAll(StorageServiceV001.loadEvents());
    notifyListeners();
  }

  Future<void> loadFromFirestore() async {
    if (familyId == null) return;
    final membersFromCloud =
        await _firestoreService.fetchFamilyMembers(familyId!);
    _members
      ..clear()
      ..addAll(membersFromCloud);

    final tasksFromCloud = await _firestoreService.fetchTasks(familyId!);
    _tasks
      ..clear()
      ..addAll(tasksFromCloud);

    final eventsFromCloud = await _firestoreService.fetchEvents(familyId!);
    _events
      ..clear()
      ..addAll(eventsFromCloud);

    notifyListeners();
  }

  Future<void> saveToFirestore() async {
    if (familyId == null) return;
    for (final member in _members) {
      await _encryptedFirestoreService.upsertFamilyMember(
        familyId: familyId!,
        memberId: member.id,
        memberData: member.toMap(),
      );
    }
    await _firestoreService.saveTasks(familyId!, _tasks);
    await _firestoreService.saveEvents(familyId!, _events);
  }

  // ---------- CRUD ----------
  void addMember(FamilyMember m) {
    _members.add(m);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  void updateMember(FamilyMember m) {
    final i = _members.indexWhere((x) => x.id == m.id);
    if (i != -1) {
      _members[i] = m;
      StorageServiceV001.saveMembers(_members);
      notifyListeners();
    }
  }

  void removeMember(FamilyMember m) {
    _members.removeWhere((x) => x.id == m.id);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  void addTask(Task t) {
    _tasks.add(t);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  void updateTask(Task t) {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i != -1) {
      _tasks[i] = t;
      StorageServiceV001.saveTasks(_tasks);
      notifyListeners();
    }
  }

  void removeTask(Task t) {
    _tasks.removeWhere((x) => x.id == t.id);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  void addEvent(Event e) {
    _events.add(e);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }

  void removeEvent(Event e) {
    _events.removeWhere((x) => x.id == e.id);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }

  // ---------- Batch set operations ----------
  /// Replace the entire list of family members with [members].
  /// This saves to local storage and notifies listeners.
  void setMembers(List<FamilyMember> members) {
    _members
      ..clear()
      ..addAll(members);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  /// Replace the entire list of tasks with [tasks].
  /// This saves to local storage and notifies listeners.
  void setTasks(List<Task> tasks) {
    _tasks
      ..clear()
      ..addAll(tasks);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  /// Replace the entire list of events with [events].
  /// This saves to local storage and notifies listeners.
  void setEvents(List<Event> events) {
    _events
      ..clear()
      ..addAll(events);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Update helpers
  //
  // The FamilyMember model uses immutable (final) fields for most properties. To
  // update a single property (e.g. avatar URL or birthday) we create a new
  // FamilyMember instance copying all existing data and replacing only the
  // updated field. The updated member then replaces the old one in the
  // underlying list and the change is persisted to storage.

  /// Update the avatar URL for the member with the given [memberId]. If
  /// [avatarUrl] is null the avatar field will be cleared.
  void updateAvatar(String memberId, String? avatarUrl) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    final m = _members[index];
    final updated = FamilyMember(
      id: m.id,
      name: m.name,
      relationship: m.relationship,
      birthday: m.birthday,
      phone: m.phone,
      email: m.email,
      avatarUrl: avatarUrl,
      socialMedia: m.socialMedia,
      hobbies: m.hobbies,
      documents: m.documents,
      documentsList: m.documentsList,
      socialNetworks: m.socialNetworks,
      messengers: m.messengers,
    );
    _members[index] = updated;
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  /// Update the birthday for the member with the given [memberId]. If
  /// [birthday] is null the birthday will be removed.
  void updateBirthday(String memberId, DateTime? birthday) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    final m = _members[index];
    final updated = FamilyMember(
      id: m.id,
      name: m.name,
      relationship: m.relationship,
      birthday: birthday,
      phone: m.phone,
      email: m.email,
      avatarUrl: m.avatarUrl,
      socialMedia: m.socialMedia,
      hobbies: m.hobbies,
      documents: m.documents,
      documentsList: m.documentsList,
      socialNetworks: m.socialNetworks,
      messengers: m.messengers,
    );
    _members[index] = updated;
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  /// Update the documents list for the member with the given [memberId]. The
  /// provided [docs] list should contain the textual representation of each
  /// document. The legacy `documents` string will be set to a comma‑separated
  /// version of [docs]. The structured `documentsList` will be created with
  /// each entry mapped as `{ 'value': doc }` to preserve the order.
  void updateDocuments(String memberId, List<String> docs) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    final m = _members[index];
    final updated = FamilyMember(
      id: m.id,
      name: m.name,
      relationship: m.relationship,
      birthday: m.birthday,
      phone: m.phone,
      email: m.email,
      avatarUrl: m.avatarUrl,
      socialMedia: m.socialMedia,
      hobbies: m.hobbies,
      documents: docs.isNotEmpty ? docs.join(', ') : null,
      documentsList: docs
          .map((doc) => <String, String>{'value': doc})
          .toList(),
      socialNetworks: m.socialNetworks,
      messengers: m.messengers,
    );
    _members[index] = updated;
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  /// Update the hobbies list for the member with the given [memberId]. The
  /// provided [hobbies] list will be persisted as a comma‑separated string in
  /// the legacy `hobbies` field. The structured list is not yet supported in
  /// the model, so consumers are expected to split the string back into a list
  /// when required.
  void updateHobbies(String memberId, List<String> hobbies) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index == -1) return;
    final m = _members[index];
    final updated = FamilyMember(
      id: m.id,
      name: m.name,
      relationship: m.relationship,
      birthday: m.birthday,
      phone: m.phone,
      email: m.email,
      avatarUrl: m.avatarUrl,
      socialMedia: m.socialMedia,
      hobbies: hobbies.isNotEmpty ? hobbies.join(', ') : null,
      documents: m.documents,
      documentsList: m.documentsList,
      socialNetworks: m.socialNetworks,
      messengers: m.messengers,
    );
    _members[index] = updated;
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

}
