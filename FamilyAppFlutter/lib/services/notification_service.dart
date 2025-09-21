/// Manages in-app notifications.  This stub implementation exposes
/// methods that do nothing, satisfying imports without adding
/// dependencies on notification libraries.
class NotificationService {
  Future<void> sendNotification(String title, String body) async {
    // Would normally trigger a local or push notification.
    return;
  }
}