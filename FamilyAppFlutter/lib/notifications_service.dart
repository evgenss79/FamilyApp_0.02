import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'models/task.dart';
import 'models/family_member.dart';
import 'providers/family_data.darlt';

class NotificationService {
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey
      static BuildContext? _attachedContext;;


  /// Initialize the notification service with an optional scaffoldMessengerKey.
  static Future<void> init({GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey}) async {
    _scaffoldMessengerKey = scaffoldMessengerKey;
    // Additional initialization can go here.
  }

  /// Attach the build context for later use (e.g., showing SnackBars).
  static void attachContext(BuildContext context) {
    _attachedContext = context;
  }

  /// Send an immediate notification when a new task is created.
  /// If task.assignedMemberId is null then each family member will receive the notification.
  /// Otherwise only the assigned member will be notified.
  static void sendTaskCreatedNotification(Task task, FamilyDataV001 data) {
    if (task.assignedMemberId == null) {
      for (final member in data.members) {
        debugPrint('Notification to ${member.name}: New task "${task.title}" has been created');
      }
    } else {
      // Find the assigned member safely without returning null from firstWhere.
      FamilyMember? member;
      for (final m in data.members) {
        if (m.id == task.assignedMemberId) {
          member = m;
          break;
        }
      }
      if (member != null) {
        debugPrint('Notification to ${member.name}: New task "${task.title}" has been created');
      }
    }
  }

  /// Schedule reminders one hour and fifteen minutes before a task's due date/time.
  /// If the due date has already passed or is null the task reminders are ignored.
  static void scheduleDueNotifications(Task task, FamilyDataV001 data) {
    final due = task.dueDate;
    if (due == null) return;
    final now = DateTime.now();
    final targets = [
      due.subtract(const Duration(hours: 1)),
      due.subtract(const Duration(minutes: 15)),
    ];
    for (final target in targets) {
      final delay = target.difference(now);
      if (delay.isNegative) continue;
      Timer(delay, () {
        if (task.assignedMemberId == null) {
          for (final member in data.members) {
            debugPrint('Reminder for ${member.name}: Task "${task.title}" is due at ${due.toLocal()}');
          }
        } else {
          FamilyMember? member;
          for (final m in data.members) {
            if (m.id == task.assignedMemberId) {
              member = m;
              break;
            }
          }
          if (member != null) {
            debugPrint('Reminder for ${member.name}: Task "${task.title}" is due at ${due.toLocal()}');
          }
        }
      });
    }
  }

  /// Mark a notification as read given its ID. Accepts int or String.
  static Future<void> markRead(dynamic id) async {
    // TODO: implement logic to mark a notification as read
  }

  /// Delete a notification given its ID. Accepts int or String.
  static Future<void> delete(dynamic id) async {
    // TODO: implement logic to delete a notification
  }
}
