import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../storage/hive_secure.dart';

import '../providers/chat_provider.dart';

/// Bootstraps Hive and wraps the app with ChatProvider.
class ChatBoot {
  static Future<void> init() async {
   await HiveSecure.initEncrypted();
  }

  static Widget withProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: child,
    );
  }

  static Future<void> openBoxes(BuildContext context) async {
    await context.read<ChatProvider>().init();
  }
}
