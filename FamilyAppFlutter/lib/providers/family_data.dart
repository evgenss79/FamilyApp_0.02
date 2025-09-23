import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class FamilyData extends ChangeNotifier {
  FamilyData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<FamilyMember> members = <FamilyMember>[];
  final List<Task> tasks = <Task>[];
  final List<Event> events = <Event>[];

  StreamSubscription<List<FamilyMember>>? _membersSub;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<Event>>? _eventsSub;

  bool _initialized = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _isLoading = true;
    notifyListeners();

    final List<FamilyMember> cachedMembers =
        await _firestore.loadCachedMembers(familyId);
    final List<Task> cachedTasks = await _firestore.loadCachedTasks(familyId);
    final List<Event> cachedEvents = await _firestore.loadCachedEvents(familyId);

    members
      ..clear()
      ..addAll(cachedMembers);
    tasks
      ..clear()
      ..addAll(cachedTasks);
    events
      ..clear()
      ..addAll(cachedEvents);

    _membersSub = _firestore.watchMembers(familyId).listen((List<FamilyMember> data) {
      members
        ..clear()
        ..addAll(data);
      notifyListeners();
    });

    _tasksSub = _firestore.watchTasks(familyId).listen((List<Task> data) {
      tasks
        ..clear()
        ..addAll(data);
      tasks.sort((Task a, Task b) =>
          (a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0)));
      notifyListeners();
    });

    _eventsSub = _firestore.watchEvents(familyId).listen((List<Event> data) {
      events
        ..clear()
        ..addAll(data);
      events.sort((Event a, Event b) => a.startDateTime.compareTo(b.startDateTime));
      notifyListeners();
    });

    _initialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initialized = false;
    await init();
  }

  Future<void> addMember(FamilyMember member) async {
    members.add(member);
    notifyListeners();
    await _firestore.createFamilyMember(familyId, member);
  }

  Future<void> updateMember(FamilyMember member) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == member.id);
    if (index != -1) {
      members[index] = member;
      notifyListeners();
    }
    await _firestore.updateFamilyMember(familyId, member);
  }

  Future<void> removeMember(FamilyMember member) async {
    members.removeWhere((FamilyMember m) => m.id == member.id);
    notifyListeners();
    await _firestore.deleteFamilyMember(familyId, member.id);
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    notifyListeners();
    await _firestore.createTask(familyId, task);
  }

  Future<void> updateTask(Task task) async {
    final int index = tasks.indexWhere((Task t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      notifyListeners();
    }
    await _firestore.updateTask(familyId, task);
  }

  Future<void> removeTask(String id) async {
    tasks.removeWhere((Task task) => task.id == id);
    notifyListeners();
    await _firestore.deleteTask(familyId, id);
  }

  Future<void> addEvent(Event event) async {
    events.add(event);
    notifyListeners();
    await _firestore.createEvent(familyId, event);
  }

  Future<void> updateEvent(Event event) async {
    final int index = events.indexWhere((Event e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      notifyListeners();
    }
    await _firestore.updateEvent(familyId, event);
  }

  Future<void> removeEvent(String id) async {
    events.removeWhere((Event event) => event.id == id);
    notifyListeners();
    await _firestore.deleteEvent(familyId, id);
  }

  FamilyMember? memberById(String id) {
    if (id.isEmpty) {
      return null;
    }
    try {
      return members.firstWhere((FamilyMember member) => member.id == id);
    } on StateError {
      return null;
    }
  }

  Future<void> updateMemberDocuments(
    String memberId, {
    String? summary,
    List<Map<String, String>>? documentsList,
  }) async {
    final int index =
        members.indexWhere((FamilyMember member) => member.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      documents: summary,
      documentsList: documentsList,
      updatedAt: DateTime.now(),
    );
    members[index] = updated;
    notifyListeners();
    await _firestore.updateFamilyMember(familyId, updated);
  }

  Future<void> updateMemberHobbies(String memberId, String? hobbies) async {
    final int index =
        members.indexWhere((FamilyMember member) => member.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      hobbies: hobbies,
      updatedAt: DateTime.now(),
    );
    members[index] = updated;
    notifyListeners();
    await _firestore.updateFamilyMember(familyId, updated);
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
    notifyListeners();
    await _firestore.updateTask(familyId, updated);
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _tasksSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }
}
