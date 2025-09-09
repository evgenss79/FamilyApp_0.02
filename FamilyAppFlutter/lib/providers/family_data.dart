import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../security/encrypted_firestore_service.dart';

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

  /// Инициализация: выбирает familyId, затем загружает данные из локального хранилища и Firestore.
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

  /// Сохранение всех списков в Firestore.
  Future<void> saveToFirestore() async {
    if (familyId == null) return;
    for (final member in _members) {
      await _encryptedFirestoreService.upsertFamilyMember(
        familyId: familyId!,
        memberId: member.id,
        memberData: member.toMap(),
      );
    }
    await _firestoreService.updateTasks(familyId!, _tasks);
    await _firestoreService.updateEvents(familyId!, _events);
  }

  // Методы для участников
  void addMember(FamilyMember member) {
    _members.add(member);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  void updateMember(FamilyMember updatedMember) {
    final index = _members.indexWhere((m) => m.id == updatedMember.id);
    if (index != -1) {
      _members[index] = updatedMember;
      StorageServiceV001.saveMembers(_members);
      notifyListeners();
    }
  }

  void removeMember(FamilyMember member) {
    _members.remove(member);
    for (final task in _tasks) {
      if (task.assignedMemberId == member.id) {
        task.assignedMemberId = null;
      }
    }
    StorageServiceV001.saveMembers(_members);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  // Методы для задач
  void addTask(Task task) {
    _tasks.add(task);
    StorageServiceV001.saveTasks(_tasks);
    // синхронизация с Firestore в фоновом режиме
    saveToFirestore();
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      StorageServiceV001.saveTasks(_tasks);
      saveToFirestore();
      notifyListeners();
    }
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    StorageServiceV001.saveTasks(_tasks);
    saveToFirestore();
    notifyListeners();
  }

  // Методы для событий
  void addEvent(Event event) {
    _events.add(event);
    StorageServiceV001.saveEvents(_events);
    saveToFirestore();
    notifyListeners();
  }

  void removeEvent(Event event) {
    _events.remove(event);
    StorageServiceV001.saveEvents(_events);
    saveToFirestore();
    notifyListeners();
  }
}
