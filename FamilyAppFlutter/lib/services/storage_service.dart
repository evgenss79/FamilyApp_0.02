import 'package:hive_flutter/hive_flutter.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';

import '../storage/hive_secure.dart';
/// A service responsible for initializing Hive and loading/saving


/// persistent data for version 0.01 of the FamilyApp. All lists are stored
/// in boxes keyed by 'data' and serialized via the models' `toMap`/`fromMap` methods.
class StorageServiceV001 {
  /// Initialize Hive and open the boxes used by this version of the application.
  static Future<void> init() async {
        await HiveSecure.initEncrypted();   
    // migratedata from old boxes if they exist
        await _migrateOldBoxes();
  }

  static List<FamilyMember> loadMembers() {
    final box = Hive.box('familyMembersV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((e) => FamilyMember.fromMap(Map<String, dynamic>.from(e as Map)))
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

  /// Migrates data from old Hive boxes (without V001 suffix) to new V001 boxes.
  /// This ensures users' data persists across app updates.
  static Future<void> _migrateOldBoxes() async {
    // Migrate family members
    if (await Hive.boxExists('familyMembers')) {
      final oldBox = await Hive.openBox('familyMembers');
      final newBox = Hive.box('familyMembersV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final members = oldData
          .map((e) =>
              FamilyMember.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      await newBox.put('data', members.map((m) => m.toMap()).toList());
      await oldBox.deleteFromDisk();
    }

    // Migrate tasks
    if (await Hive.boxExists('tasks')) {
      final oldBox = await Hive.openBox('tasks');
      final newBox = Hive.box('tasksV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final tasks = oldData
          .map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      await newBox.put('data', tasks.map((t) => t.toMap()).toList());
      await oldBox.deleteFromDisk();
    }

    // Migrate events
    if (await Hive.boxExists('events')) {
      final oldBox = await Hive.openBox('events');
      final newBox = Hive.box('eventsV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final events = oldData
          .map((e) => Event.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      await newBox.put('data', events.map((e) => e.toMap()).toList());
      await oldBox.deleteFromDisk();
    }
  }
}
