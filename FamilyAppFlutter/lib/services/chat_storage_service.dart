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

    // migrate data from old boxes if they exist
    await _migrateOldBoxes();
  }

  /// Loads all conversations from the Hive box.
  static List<Conversation> loadConversations() {
    final box = Hive.box('conversationsV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) =>
            Conversation.fromMap(Map<String, dynamic>.from(map as Map)))
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
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => Message.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  /// Saves the list of messages to the Hive box.
  static void saveMessages(List<Message> messages) {
    final box = Hive.box('messagesV001');
    final data = messages.map((message) => message.toMap()).toList();
    box.put('data', data);
  }

  /// Migrates data from old boxes (without V001 suffix) to new boxes.
  static Future<void> _migrateOldBoxes() async {
    // Migrate conversations
    if (await Hive.boxExists('conversations')) {
      final oldBox = await Hive.openBox('conversations');
      final newBox = Hive.box('conversationsV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final conversations = oldData
          .map((map) =>
              Conversation.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();
      await newBox.put(
          'data', conversations.map((c) => c.toMap()).toList());
      await oldBox.deleteFromDisk();
    }

    // Migrate messages
    if (await Hive.boxExists('messages')) {
      final oldBox = await Hive.openBox('messages');
      final newBox = Hive.box('messagesV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final messages = oldData
          .map((map) =>
              Message.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();
      await newBox.put(
          'data', messages.map((m) => m.toMap()).toList());
      await oldBox.deleteFromDisk();
    }
  }
}
