import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';

/// Holds shared state for family members, tasks and events.  This
/// provider exposes simple methods to add items and notifies
/// listeners when changes occur.  More complex business logic can be
/// added as the application grows.
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

  /// Removes a [member] from the family and notifies listeners.
  void removeMember(FamilyMember member) {
    members.remove(member);
    notifyListeners();
  }

  /// Adds a [task] and notifies listeners.
  void addTask(Task task) {
    tasks.add(task);
    notifyListeners();
  }

  /// Adds an [event] and notifies listeners.
  void addEvent(Event event) {
    events.add(event);
    notifyListeners();
  }
}