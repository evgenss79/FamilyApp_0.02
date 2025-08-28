import 'package:hive_flutter/hive_flutter.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';

/// A service responsible for initializing Hive and loading/saving
/// persistent data for the FamilyApp. All lists are stored in boxes
/// keyed by 'data' and serialized via the models' `toMap`/`fromMap` methods.
class StorageService {
  /// Initialize Hive and open the boxes used by the application. This
  /// method must be called before any load or save operations.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('familyMembers');
    await Hive.openBox('tasks');
    await Hive.openBox('events');
  }

  /// Load the list of family members from the Hive box.
  static List<FamilyMember> loadMembers() {
    final box = Hive.box('familyMembers');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) =>
            FamilyMember.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Persist the list of family members to the Hive box.
  static Future<void> saveMembers(List<FamilyMember> members) async {
    final box = Hive.box('familyMembers');
    await box.put('data', members.map((m) => m.toMap()).toList());
  }

  /// Load the list of tasks from the Hive box.
  static List<Task> loadTasks() {
    final box = Hive.box('tasks');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Persist the list of tasks to the Hive box.
  static Future<void> saveTasks(List<Task> tasks) async {
    final box = Hive.box('tasks');
    await box.put('data', tasks.map((t) => t.toMap()).toList());
  }

  /// Load the list of events from the Hive box.
  static List<Event> loadEvents() {
    final box = Hive.box('events');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) => Event.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Persist the list of events to the Hive box.
  static Future<void> saveEvents(List<Event> events) async {
    final box = Hive.box('events');
    await box.put('data', events.map((e) => e.toMap()).toList());
  }
}
