import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../providers/family_data.dart';

/// A very simple notification service used to simulate delivery of task
/// notifications within the app.  In this basic implementation notifications
/// are printed to the debug console.  In a full‑featured application this
/// class could be replaced with a platform specific local notification
/// service (e.g. `flutter_local_notifications`) to schedule actual
/// push notifications on iOS and Android.
class NotificationService {
  /// Send an immediate notification to the appropriate recipients when a
  /// new task is created.  If [task.assignedMemberId] is null the task is
  /// considered a shared family task and each member will receive the
  /// notification.  Otherwise only the assigned member will be notified.
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
        debugPrint(
            'Notification to ${member.name}: You have been assigned a new task "${task.title}"');
      }
    }
  }

  /// Schedule reminders one hour and fifteen minutes before a task's due
  /// date/time.  If the due date has already passed or is null the
  /// reminders are ignored.  When the timers fire, a notification is
  /// delivered to the appropriate recipients (all members for shared tasks,
  /// or just the assigned member for individual tasks).
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
            debugPrint(
                'Reminder for ${member.name}: Task "${task.title}" is due at ${due.toLocal()}');
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
            debugPrint(
                'Reminder for ${member.name}: Task "${task.title}" is due at ${due.toLocal()}');
          }
        }
      });
    }
  }
}