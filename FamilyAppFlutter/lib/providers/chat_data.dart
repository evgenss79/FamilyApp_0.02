import 'package:flutter/foundation.dart';

import '../models/chat.dart';

/// Simple provider that holds a list of chats in memory.  For more
/// advanced functionality such as persistence, use [ChatProvider]
/// which interacts with Hive storage.  This class exists to satisfy
/// dependencies in the simplified UI screens.
class ChatData extends ChangeNotifier {
  final List<Chat> chats = [];

  void addChat(Chat chat) {
    chats.add(chat);
    notifyListeners();
  }
}