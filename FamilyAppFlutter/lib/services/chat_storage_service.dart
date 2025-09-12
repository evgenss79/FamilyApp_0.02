import 'package:hive/hive.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../storage/hive_secure.dart';

class ChatStorageServiceV001 {
  /// Initializes Hive adapters and opens/encrypts boxes for conversations and messages.
  static Future<void> init() async {
    // Ensure encrypted Hive initialized (cipher + secure key)
    await HiveSecure.initEncrypted();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(ConversationAdapter().typeId)) {
      Hive.registerAdapter(ConversationAdapter());
    }
    }

    // Open boxes if you use typed boxes; if not, rely on HiveSecure inside Storage layer
    // Here we keep simple map-based storage with single "data" key per V001 box.
    await _ensureBoxes();

    // Migrate data from old boxes if they exist
    await _migrateOldBoxes();
  }

  static Future<void> _ensureBoxes() async {
    if (!Hive.isBoxOpen('conversationsV001')) {
      await Hive.openBox('conversationsV001');
    }
    if (!Hive.isBoxOpen('messagesV001')) {
      await Hive.openBox('messagesV001');
    }
  }

  /// Loads all conversations from the Hive box.
  static List<Conversation> loadConversations() {
    final box = Hive.box('conversationsV001');
    final data = box.get('data', defaultValue: []) as List;
    return data
        .map((map) => Conversation.fromMap(Map<String, dynamic>.from(map as Map)))
        .toList();
  }

  /// Saves the list of conversations to the Hive box.
  static void saveConversations(List<Conversation> conversations) {
    final box = Hive.box('conversationsV001');
    final data = conversations.map((c) => c.toMap()).toList();
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
    final data = messages.map((m) => m.toMap()).toList();
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
          .map((map) => Conversation.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();
      await newBox.put('data', conversations.map((c) => c.toMap()).toList());
      await oldBox.deleteFromDisk();
    }

    // Migrate messages
    if (await Hive.boxExists('messages')) {
      final oldBox = await Hive.openBox('messages');
      final newBox = Hive.box('messagesV001');
      final oldData = oldBox.get('data', defaultValue: []) as List;
      final messages = oldData
          .map((map) => Message.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();
      await newBox.put('data', messages.map((m) => m.toMap()).toList());
      await oldBox.deleteFromDisk();
    }
  }
}
