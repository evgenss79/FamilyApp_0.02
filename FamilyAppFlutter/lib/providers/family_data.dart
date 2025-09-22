import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../models/task.dart';

/// Holds shared state for family members, tasks and events.  This
/// provider exposes methods to add and modify items and notifies
/// listeners when changes occur.
class FamilyData extends ChangeNotifier {
  /// All members in the family.
  final List<FamilyMember> members = [];

  /// All tasks tracked in the app.
  final List<Task> tasks = [];

  /// All events tracked in the app.
  final List<Event> events = [];

  /// Adds a [member] to the family and notifies listeners.
  void addMember(FamilyMember member) {
    members.add(member);
    notifyListeners();
  }

  /// Returns the member with [id] or null if not found.
  FamilyMember? memberById(String id) {
    try {
      return members.firstWhere((member) => member.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates an existing [member] if it is present in the list.
  void updateMember(FamilyMember member) {
    final index = members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      members[index] = member;
      notifyListeners();
    }
  }

  /// Removes a [member] from the family and notifies listeners.
  void removeMember(FamilyMember member) {
    members.removeWhere((m) => m.id == member.id);
    notifyListeners();
  }

  /// Removes a member by identifier.
  void removeMemberById(String id) {
    members.removeWhere((member) => member.id == id);
    notifyListeners();
  }

  /// Updates the documents attached to a member.
  void updateMemberDocuments(
    String memberId, {
    String? summary,
    List<Map<String, String>>? documentsList,
  }) {
    final member = memberById(memberId);
    if (member == null) return;
    updateMember(
      member.copyWith(
        documents: summary,
        documentsList: documentsList,
      ),
    );
  }

  /// Updates the hobbies stored for a member.
  void updateMemberHobbies(String memberId, String? hobbies) {
    final member = memberById(memberId);
    if (member == null) return;
    updateMember(member.copyWith(hobbies: hobbies));
  }

  /// Adds a [task] and notifies listeners.
  void addTask(Task task) {
    tasks.add(task);
    notifyListeners();
  }

  /// Returns the task with [id] or null if not found.
  Task? taskById(String id) {
    try {
      return tasks.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates an existing task.
  void updateTask(Task task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      notifyListeners();
    }
  }

  /// Removes a task by identifier.
  void removeTask(String id) {
    tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  /// Updates the status of a task.
  void updateTaskStatus(String id, TaskStatus status) {
    final task = taskById(id);
    if (task == null) return;
    task.status = status;
    notifyListeners();
  }

  /// Assigns a task to a member.
  void assignTask(String id, String? assigneeId) {
    final task = taskById(id);
    if (task == null) return;
    task.assigneeId = assigneeId;
    notifyListeners();
  }

  /// Adds an [event] and notifies listeners.
  void addEvent(Event event) {
    events.add(event);
    notifyListeners();
  }

  /// Returns the event with [id] or null if not found.
  Event? eventById(String id) {
    try {
      return events.firstWhere((event) => event.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates an existing event.
  void updateEvent(Event event) {
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      notifyListeners();
    }
  }

  /// Removes an event by identifier.
  void removeEvent(String id) {
    events.removeWhere((event) => event.id == id);
    notifyListeners();
  }
}
