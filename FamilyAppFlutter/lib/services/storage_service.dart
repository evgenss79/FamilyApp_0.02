import 'package:hive_flutter/hive_flutter.dart';

import '../models/family_member_v001.dart';
import '../models/task.dart';
import '../models/event.dart';

/// A service responsible for initializing Hive and loading/saving
/// persistent data for version 0.01 of the FamilyApp. All lists are stored in boxes
/// keyed by 'data' and serialized via the models' `toMap`/`fromMap` methods.
class StorageServiceV001 {
  /// Initialize Hive and open the boxes used by this version of the application.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('familyMembersV001');
    await Hive.openBox('tasksV001');
    await Hive.openBox('eventsV001');
  }

  static List<FamilyMember> loadMembers() {
    final box = Hive.box('familyMembersV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) =>
            FamilyMember.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveMembers(List<FamilyMember> members) async {
    final box = Hive.box('familyMembersV001');
    await box.put('data', members.map((m) => m.toMap()).toList());
  }

  static List<Task> loadTasks() {
    final box = Hive.box('tasksV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final box = Hive.box('tasksV001');
    await box.put('data', tasks.map((t) => t.toMap()).toList());
  }

  static List<Event> loadEvents() {
    final box = Hive.box('eventsV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) => Event.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveEvents(List<Event> events) async {
    final box = Hive.box('eventsV001');
    await box.put('data', events.map((e) => e.toMap()).toList());
  }
}
