import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> _effectiveKey = scaffoldMessengerKey;

  /// Инициализация. Параметр сделан необязательным для обратной совместимости.
  static Future<void> init({GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey}) async {
    _effectiveKey = scaffoldMessengerKey ?? NotificationService.scaffoldMessengerKey;
    // Здесь можно инициализировать локальные/пуш-уведомления.
  }

  /// Совместимость со старым кодом (no-op).
  static void attachContext(BuildContext context) {
    // Используйте NotificationService.scaffoldMessengerKey в MaterialApp.scaffoldMessengerKey
  }

  static ScaffoldMessengerState? get _messenger => _effectiveKey.currentState;

  static void showSnack(String message, {SnackBarAction? action, Duration? duration}) {
    final bar = SnackBar(
      content: Text(message),
      action: action,
      duration: duration ?? const Duration(seconds: 3),
    );
    _messenger?..clearSnackBars()..showSnackBar(bar);
  }

  static MaterialBanner buildBanner(String text, {List<Widget>? actions}) {
    return MaterialBanner(
      content: Text(text),
      actions: actions ?? [
        TextButton(
          onPressed: () => _messenger?.clearMaterialBanners(),
          child: const Text('OK'),
        )
      ],
    );
  }

  static void showBanner(MaterialBanner banner) {
    _messenger?..clearMaterialBanners()..showMaterialBanner(banner);
  }
}
