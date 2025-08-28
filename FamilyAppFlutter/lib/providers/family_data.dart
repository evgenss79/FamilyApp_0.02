import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';

class FamilyData extends ChangeNotifier {
  final List<FamilyMember> _members = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];

  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Event> get events => List.unmodifiable(_events);

  void addMember(FamilyMember member) {
    _members.add(member);
    notifyListeners();
  }

  void removeMember(FamilyMember member) {
    _members.remove(member);
    for (var task in _tasks) {
      if (task.assignedMemberId == member.id) {
        task.assignedMemberId = null;
      }
    }
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }

  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void removeEvent(Event event) {
    _events.remove(event);
    notifyListeners();
  }
}
