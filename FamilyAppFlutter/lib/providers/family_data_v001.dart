import 'package:flutter/foundation.dart';
import '../models/family_member_v001.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../services/storage_service_v001.dart';

class FamilyDataV001 extends ChangeNotifier {
  final List<FamilyMember> _members = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];

  List<FamilyMember> get members => _members;
  List<Task> get tasks => _tasks;
  List<Event> get events => _events;

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

  void addMember(FamilyMember member) {
    _members.add(member);
    StorageServiceV001.saveMembers(_members);
    notifyListeners();
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

  void addTask(Task task) {
    _tasks.add(task);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    StorageServiceV001.saveTasks(_tasks);
    notifyListeners();
  }

  void addEvent(Event event) {
    _events.add(event);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }

  void removeEvent(Event event) {
    _events.remove(event);
    StorageServiceV001.saveEvents(_events);
    notifyListeners();
  }
}
