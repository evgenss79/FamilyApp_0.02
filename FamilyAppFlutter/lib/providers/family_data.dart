import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../security/encrypted_firestore_service.dart';
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
    _members..clear()..addAll(membersFromCloud);

    final tasksFromCloud = await _firestoreService.fetchTasks(familyId!);
    _tasks..clear()..addAll(tasksFromCloud);

    final eventsFromCloud = await _firestoreService.fetchEvents(familyId!);
    _events..clear()..addAll(eventsFromCloud);

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

 /
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