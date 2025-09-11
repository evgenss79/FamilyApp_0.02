import '../models/task.dart';

class NotificationService {
  static Future<void> init() async {
    // платформа-специфичная инициализация
  }

  static Future<void> sendTaskCreatedNotification(Task task) async {
    // TODO: в будущем — отправка уведомления о создании задачи
  }

  static Future<void> scheduleDueNotifications(Task task) async {
    // TODO: в будущем — планирование уведомлений по сроку задачи
  }
}
