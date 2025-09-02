import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../providers/family_data.dart';
import '../models/family_member.dart';

class NotificationService {
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  static BuildContext? _attachedContext;

  static Future<void> init({GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey}) async {
    _scaffoldMessengerKey = scaffoldMessengerKey;
  }

  static void attachContext(BuildContext context) {
    _attachedContext = context;
  }

  static void sendTaskCreatedNotification(Task task, FamilyDataV001 data) {
    if (task.assignedMemberId == null) {
      for (final member in data.members) {
        debugPrint('Notification to ${member.name}: New task \"${task.title}\" has been created');
      }
    } else {
      final member = data.members.firstWhere(
        (m) => m.id == task.assignedMemberId,
        orElse: () => null,
      );
      if (member != null) {
        debugPrint('Notification to ${member.name}: You have been assigned a new task \"${task.title}\"');
      }
    }
  }

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
            debugPrint('Reminder for ${member.name}: Task \"${task.title}\" is due at ${due.toLocal()}');
          }
        } else {
          final member = data.members.firstWhere(
            (m) => m.id == task.assignedMemberId,
            orElse: () => null,
          );
          if (member != null) {
            debugPrint('Reminder for ${member.name}: Task \"${task.title}\" is due at ${due.toLocal()}');
          }
        }
      });
    }
  }

  static Future<void> markRead(dynamic id) async {
    // TODO: implement markRead logic
  }

  static Future<void> delete(dynamic id) async {
    // TODO: implement delete logic
  }
}
