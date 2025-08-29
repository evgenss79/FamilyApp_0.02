import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service.dart';

class FamilyData extends ChangeNotifier {
  final List<FamilyMember> _members = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];

  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Event> get events => List.unmodifiable(_events);

  Future<void> loadFromStorage() async {
    _members
      ..clear()
      ..addAll(StorageService.loadMembers());
    _tasks
      ..clear()
      ..addAll(StorageService.loadTasks());
    _events
      ..clear()
      ..addAll(StorageService.loadEvents());
    notifyListeners();
  }

  void addMember(FamilyMember member) {
    _members.add(member);
    StorageService.saveMembers(_members);
    notifyListeners();
  }

  void removeMember(FamilyMember member) {
    _members.remove(member);
    // Remove assignment from tasks
    for (var task in _tasks) {
      if (task.assignedMemberId == member.id) {
        task.assignedMemberId = null;
      }
    }
    StorageService.saveMembers(_members);
    StorageService.saveTasks(_tasks);
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    StorageService.saveTasks(_tasks);
    notifyListeners();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    StorageService.saveTasks(_tasks);
    notifyListeners();
  }

  void addEvent(Event event) {
    _events.add(event);
    StorageService.saveEvents(_events);
    notifyListeners();
  }

  void removeEvent(Event event) {
    _events.remove(event);
    StorageService.saveEvents(_events);
    notifyListeners();
  }
}
