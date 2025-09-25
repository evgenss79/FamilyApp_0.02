import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

/// Holds shared state for family members, tasks and events. This provider
/// orchestrates persistence through [FirestoreService] and keeps local lists
/// updated for the UI.
class FamilyData extends ChangeNotifier {
  FamilyData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<FamilyMember> members = <FamilyMember>[];
  final List<Task> tasks = <Task>[];
  final List<Event> events = <Event>[];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final List<FamilyMember> fetchedMembers =
          await _firestore.fetchFamilyMembers(familyId);
      final List<Task> fetchedTasks = await _firestore.fetchTasks(familyId);
      final List<Event> fetchedEvents = await _firestore.fetchEvents(familyId);
      members
        ..clear()
        ..addAll(fetchedMembers);
      tasks
        ..clear()
        ..addAll(fetchedTasks);
      _sortTasks();
      events
        ..clear()
        ..addAll(fetchedEvents);
      _loaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  FamilyMember? memberById(String? memberId) {
    if (memberId == null) {
      return null;
    }
    try {
      return members.firstWhere((FamilyMember member) => member.id == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMember(FamilyMember member) async {
    await _firestore.upsertFamilyMember(familyId, member);
    members.add(member);
    notifyListeners();
  }

  Future<void> updateMember(FamilyMember member) async {
    await _firestore.upsertFamilyMember(familyId, member);
    final int index = members.indexWhere((FamilyMember m) => m.id == member.id);
    if (index != -1) {
      members[index] = member;
      notifyListeners();
    }
  }

  Future<void> updateMemberDocuments(
    String memberId, {
    String? summary,
    List<Map<String, String>>? documentsList,
  }) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      documents: summary,
      documentsList: documentsList,
    );
    members[index] = updated;
    notifyListeners();
    await _firestore.updateFamilyMember(familyId, updated);
  }

  Future<void> updateMemberNetworks({
    required String memberId,
    List<Map<String, String>>? socialNetworks,
    List<Map<String, String>>? messengers,
    String? socialSummary,
  }) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      socialNetworks: socialNetworks,
      messengers: messengers,
      socialMedia: socialSummary,
    );
    members[index] = updated;
    notifyListeners();
    await _firestore.updateFamilyMember(familyId, updated);
  }

  Future<void> updateMemberHobbies(String memberId, String? hobbies) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(hobbies: hobbies);
    members[index] = updated;
    notifyListeners();
    await _firestore.updateFamilyMember(familyId, updated);
  }

  Future<void> removeMember(FamilyMember member) async {
    await _firestore.deleteFamilyMember(familyId, member.id);
    members.removeWhere((FamilyMember m) => m.id == member.id);
    notifyListeners();
  }

  Future<void> removeMemberById(String id) async {
    await _firestore.deleteFamilyMember(familyId, id);
    members.removeWhere((FamilyMember member) => member.id == id);
    notifyListeners();
  }

  Task? taskById(String id) {
    try {
      return tasks.firstWhere((Task task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    await _firestore.upsertTask(familyId, task);
    tasks.add(task);
    _sortTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _firestore.upsertTask(familyId, task);
    final int index = tasks.indexWhere((Task t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      _sortTasks();
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final int index = tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    final Task updated = tasks[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    tasks[index] = updated;
    _sortTasks();
    notifyListeners();
    await _firestore.updateTask(familyId, updated);
  }

  Future<void> assignTask(String id, String? assigneeId) async {
    final int index = tasks.indexWhere((Task task) => task.id == id);
    if (index == -1) {
      return;
    }
    final Task updated = tasks[index].copyWith(assigneeId: assigneeId);
    tasks[index] = updated;
    notifyListeners();
    await _firestore.updateTask(familyId, updated);
  }

  Future<void> removeTask(String id) async {
    await _firestore.deleteTask(familyId, id);
    tasks.removeWhere((Task task) => task.id == id);
    notifyListeners();
  }

  Event? eventById(String id) {
    try {
      return events.firstWhere((Event event) => event.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addEvent(Event event) async {
    await _firestore.upsertEvent(familyId, event);
    events.add(event);
    notifyListeners();
  }

  Future<void> updateEvent(Event event) async {
    await _firestore.upsertEvent(familyId, event);
    final int index = events.indexWhere((Event e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      notifyListeners();
    }
  }

  Future<void> removeEvent(String id) async {
    await _firestore.deleteEvent(familyId, id);
    events.removeWhere((Event event) => event.id == id);
    notifyListeners();
  }

  void _sortTasks() {
    tasks.sort((Task a, Task b) {
      final DateTime aDue = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDue = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDue.compareTo(bDue);
    });
  }
}
