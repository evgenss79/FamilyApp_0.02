import 'package:hive/hive.dart';

import '../models/family_member.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/schedule_item.dart';
import '../storage/hive_secure.dart';

/// Service responsible for loading and saving persistent data in Hive boxes.
///
/// This class encapsulates interactions with encrypted Hive boxes used by
/// FamilyApp. It supports migration of old, unencrypted boxes and provides
/// typed convenience methods for serializing and deserializing model objects.
class StorageServiceV001 {
  /// Initializes Hive boxes with encryption and performs any necessary
  /// migrations. Must be called before any load/save operations.
  static Future<void> init() async {
    await HiveSecure.initEncrypted();
    await _migrateOldBoxes();
  }

  // ---------- Family Members ----------
  static List<FamilyMember> loadMembers() {
    final box = Hive.box('familyMembersV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => FamilyMember.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  static Future<void> saveMembers(List<FamilyMember> members) async {
    final box = Hive.box('familyMembersV001');
    final data = members.map((m) => m.toMap()).toList();
    await box.put('data', data);
  }

  // ---------- Tasks ----------
  static List<Task> loadTasks() {
    final box = Hive.box('tasksV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => Task.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final box = Hive.box('tasksV001');
    final data = tasks.map((t) => t.toMap()).toList();
    await box.put('data', data);
  }

  // ---------- Events ----------
  static List<Event> loadEvents() {
    final box = Hive.box('eventsV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => Event.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  static Future<void> saveEvents(List<Event> events) async {
    final box = Hive.box('eventsV001');
    final data = events.map((e) => e.toMap()).toList();
    await box.put('data', data);
  }

  // ---------- Schedule Items ----------
  static List<ScheduleItem> loadScheduleItems() {
    final box = Hive.box('scheduleItemsV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => ScheduleItem.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  static Future<void> saveScheduleItems(List<ScheduleItem> items) async {
    final box = Hive.box('scheduleItemsV001');
    final data = items.map((item) => item.toMap()).toList();
    await box.put('data', data);
  }

  /// Migrates data from legacy, unversioned boxes to the new versioned boxes.
  ///
  /// If old boxes exist (without the V001 suffix), their contents are
  /// transferred to the corresponding V001 boxes and the old boxes are
  /// removed. This method should be idempotent.
  static Future<void> _migrateOldBoxes() async {
    // Migrate family members
    if (await Hive.boxExists('familyMembers')) {
      final oldBox = await Hive.openBox('familyMembers');
      final newBox = Hive.box('familyMembersV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      await newBox.put('data', oldData);
      await oldBox.deleteFromDisk();
    }
    // Migrate tasks
    if (await Hive.boxExists('tasks')) {
      final oldBox = await Hive.openBox('tasks');
      final newBox = Hive.box('tasksV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      await newBox.put('data', oldData);
      await oldBox.deleteFromDisk();
    }
    // Migrate events
    if (await Hive.boxExists('events')) {
      final oldBox = await Hive.openBox('events');
      final newBox = Hive.box('eventsV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      await newBox.put('data', oldData);
      await oldBox.deleteFromDisk();
    }
    // Migrate schedule items
    if (await Hive.boxExists('scheduleItems')) {
      final oldBox = await Hive.openBox('scheduleItems');
      final newBox = Hive.box('scheduleItemsV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      await newBox.put('data', oldData);
      await oldBox.deleteFromDisk();
    }
  }
}