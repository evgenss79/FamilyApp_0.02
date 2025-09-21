import 'package:flutter/material.dart';
import '../models/task.dart';

class NotificationService {
  /// Ключ для ScaffoldMessenger — подключите его в MaterialApp.scaffoldMessengerKey
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> init() async {
    // Платформенная инициализация при необходимости (пока noop)
  }

  static ScaffoldMessengerState? get _m => scaffoldMessengerKey.currentState;

  static void showSnack(String message) {
    final m = _m;
    if (m == null) return;
    m.clearSnackBars();
    m.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Sends a notification immediately when a new [task] is created.
  /// In this simplified version we show a snackbar with the task title.
  /// In a real app this could trigger a push/local notification.
  static Future<void> sendTaskCreatedNotification(Task task) async {
    showSnack('New task created: ${task.title}');
  }

  /// Schedule a notification to alert when the task's due date/time is
  /// approaching. This uses a delayed Future to trigger a snackbar at
  /// the due time. If the task has no endDateTime, this method does
  /// nothing. In a real application this could integrate with
  /// flutter_local_notifications to schedule a local notification.
  static Future<void> scheduleDueNotifications(Task task) async {
    final due = task.endDateTime;
    if (due == null) return;
    final now = DateTime.now();
    final duration = due.difference(now);
    if (duration.isNegative) return;
    Future.delayed(duration, () {
      showSnack('Task due: ${task.title}');
    });
  }

  /// Schedule a custom reminder notification for the given [task] at the
  /// specified [reminderTime]. This can be used to set arbitrary
  /// reminders independent of the task's due date. In this basic
  /// implementation we simply show a snackbar at the scheduled time.
  /// Real implementations could integrate with flutter_local_notifications
  /// or Firebase Cloud Messaging to trigger local or push alerts.
  static Future<void> scheduleCustomReminder(Task task, DateTime reminderTime) async {
    final now = DateTime.now();
    final duration = reminderTime.difference(now);
    if (duration.isNegative) return;
    // Schedule a delayed Future to show a snackbar. In a real app,
    // this could be replaced by proper notification scheduling.
    Future.delayed(duration, () {
      showSnack('Reminder: ${task.title}');
    });
  }
}
