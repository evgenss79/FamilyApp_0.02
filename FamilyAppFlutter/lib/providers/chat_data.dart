import 'package:flutter/foundation.dart';

import '../models/conversation.dart';

class ChatData extends ChangeNotifier {
  final List<Conversation> chats = <Conversation>[];

  void addChat(Conversation chat) {
    chats.add(chat);
    notifyListeners();
  }
}
