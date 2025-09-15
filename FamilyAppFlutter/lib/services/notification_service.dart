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

  static Future<void> sendTaskCreatedNotification(Task task) async {
    // TODO: интеграция локальных/Push-уведомлений при необходимости
  }

  static Future<void> scheduleDueNotifications(Task task) async {
    // TODO: планирование уведомлений по дедлайну задачи
  }
}
