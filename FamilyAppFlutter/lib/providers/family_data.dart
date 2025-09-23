import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

/// Holds shared state for family members, tasks and events.  This
/// provider exposes methods to add and modify items and notifies
/// listeners when changes occur.
class FamilyData extends ChangeNotifier {
  FamilyData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  /// All members in the family.
  final List<FamilyMember> members = [];

  /// All tasks tracked in the app.
  final List<Task> tasks = [];

  FamilyMember? memberById(String? memberId) {
    if (memberId == null) {
      return null;
    }
    for (final FamilyMember member in members) {
      if (member.id == memberId) {
        return member;
      }
    }
    return null;
  }

  FamilyMember? findMemberById(String? memberId) => memberById(memberId);
  StreamSubscription<List<FamilyMember>>? _membersSub;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<Event>>? _eventsSub;

  bool _isLoading = false;
  bool _loaded = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedMembers = await _firestore.fetchFamilyMembers(familyId);
      final fetchedTasks = await _firestore.fetchTasks(familyId);
      final fetchedEvents = await _firestore.fetchEvents(familyId);
      members
        ..clear()
        ..addAll(fetchedMembers);
      tasks
        ..clear()
        ..addAll(fetchedTasks);
      events
        ..clear()
        ..addAll(fetchedEvents);
      _loaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forces a reload of the data from Firestore.
  Future<void> refresh() async {
    _loaded = false;
    await load();
  }

  /// Returns the member with [id] or null if not found.
  FamilyMember? memberById(String id) {
    try {
      return members.firstWhere((member) => member.id == id);
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
    final index = members.indexWhere((m) => m.id == member.id);
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
    members.removeWhere((m) => m.id == member.id);
    notifyListeners();
  }

  Future<void> removeMemberById(String id) async {
    await _firestore.deleteFamilyMember(familyId, id);
    members.removeWhere((member) => member.id == id);
    notifyListeners();
  }

  Future<void> updateMemberDocuments(
    String memberId, {
    String? summary,
    List<Map<String, String>>? documentsList,
  }) async {
    final member = memberById(memberId);
    if (member == null) return;
    await updateMember(
      member.copyWith(
        documents: summary,
        documentsList: documentsList,
      ),
    );
  }

  Future<void> updateMemberNetworks({
    required String memberId,
    List<Map<String, String>>? socialNetworks,
    List<Map<String, String>>? messengers,
    String? socialSummary,
  }) async {
    final member = memberById(memberId);
    if (member == null) return;
    await updateMember(
      member.copyWith(
        socialNetworks: socialNetworks,
        messengers: messengers,
        socialMedia: socialSummary,
      ),
    );
  }

  Future<void> updateMemberHobbies(String memberId, String? hobbies) async {
    final member = memberById(memberId);
    if (member == null) return;
    await updateMember(member.copyWith(hobbies: hobbies));
  }

  Task? taskById(String id) {
    try {
      return tasks.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    await _firestore.upsertTask(familyId, task);
    tasks.add(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _firestore.upsertTask(familyId, task);
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final int index = tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    final Task updated = tasks[index].copyWith(status: status);
    tasks[index] = updated;
    tasks.sort((Task a, Task b) =>
        (a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0)));
    notifyListeners();
    await _firestore.updateTask(familyId, updated);
  }

  Future<void> removeTask(String id) async {
    await _firestore.deleteTask(familyId, id);
    tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    final task = taskById(id);
    if (task == null) return;
    task.status = status;
    await _firestore.upsertTask(familyId, task);
    notifyListeners();
  }

  Future<void> assignTask(String id, String? assigneeId) async {
    final task = taskById(id);
    if (task == null) return;
    task.assigneeId = assigneeId;
    await _firestore.upsertTask(familyId, task);
    notifyListeners();
  }

  Event? eventById(String id) {
    try {
      return events.firstWhere((event) => event.id == id);
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
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      notifyListeners();
    }
  }

  Future<void> removeEvent(String id) async {
    await _firestore.deleteEvent(familyId, id);
    events.removeWhere((event) => event.id == id);
    notifyListeners();
  }
}
