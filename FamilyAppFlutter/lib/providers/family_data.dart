import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service.dart';

/// Provider that manages lists of family members, tasks, and events.
///
/// This class wraps access to the underlying [StorageServiceV001] to
/// persist changes whenever members, tasks or events are added, removed or
/// updated.  It exposes methods to load the initial state from storage and
/// to update individual tasks.  Classes that listen to this provider will be
/// notified whenever the underlying lists change.
class FamilyDataV001 extends ChangeNotifier {
  final List<FamilyMember> _members = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];

  List<FamilyMember> get members => _members;
  List<Task> get tasks => _tasks;
  List<Event> get events => _events;

  /// Loads members, tasks and events from persistent storage.  This
  /// overwrites any existing in-memory lists.  After loading, listeners
  /// are notified.
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

  /// Adds a new [member] to the list and persists the change.
  void addMember(FamilyMember member) {
    _members.add(member);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
  }

  /// Removes [member] from the list.  Any tasks assigned to the member
  /// will have their [Task.assignedMemberId] cleared.  Updates are
  /// persisted and listeners are notified.
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

  /// Adds a new [task] to the list and persists the change.
  void addTask(Task task) {
    _tasks.add(task);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  /// Updates an existing task.  The [updatedTask] must have the same
  /// identifier as an existing task in the list.  If found, the task is
  /// replaced and the updated list is persisted.  Listeners are
  /// notified of the change.
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      StorageServiceV001.saveTasks(_tasks);
      notifyListeners();
    }
  }

  /// Removes [task] from the list and persists the change.
  void removeTask(Task task) {
    _tasks.remove(task);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  /// Adds a new [event] to the list and persists the change.
  void addEvent(Event event) {
    _events.add(event);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }

  /// Removes [event] from the list and persists the change.
  void removeEvent(Event event) {
    _events.remove(event);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }
}