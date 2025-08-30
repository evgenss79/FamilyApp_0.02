import 'package:hive/hive.dart';

import '../models/conversation.dart';
import '../models/message.dart';

class ChatStorageServiceV001 {
  /// Initializes Hive adapters and opens boxes for conversations and messages.
  static Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(ConversationAdapter().typeId)) {
      Hive.registerAdapter(ConversationAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageAdapter().typeId)) {
      Hive.registerAdapter(MessageAdapter());
    }

    // Open Hive boxes
    await Hive.openBox('conversationsV001');
    await Hive.openBox('messagesV001');
  }

  /// Loads all conversations from the Hive box.
  static List<Conversation> loadConversations() {
    final box = Hive.box('conversationsV001');
    final data = box.get('data', defaultValue: []) as List<dynamic>;
    return data
        .map((map) => Conversation.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  /// Saves the list of conversations to the Hive box.
  static void saveConversations(List<Conversation> conversations) {
    final box = Hive.box('conversationsV001');
    final data = conversations.map((conversation) => conversation.toMap()).toList();
    box.put('data', data);
  }

  /// Loads all messages from the Hive box.
  static List<Message> loadMessages() {
    final box = Hive.box('messagesV001');
    final data = box.get('data', defaultValue: []) as List<dynamic>;
    return data
        .map((map) => Message.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  /// Saves the list of messages to the Hive box.
  static void saveMessages(List<Message> messages) {
    final box = Hive.box('messagesV001');
    final data = messages.map((message) => message.toMap()).toList();
    box.put('data', data);
  }
}
