import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_storage_service.dart';

class ChatDataV001 with ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];

  // Returns an unmodifiable view of the conversations.
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  // Returns the list of messages for a given conversation.
  List<Message> messagesForConversation(String conversationId) {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  // Loads conversations and messages from persistent storage.
  Future<void> loadData() async {
    await ChatStorageServiceV001.init();
    _conversations = ChatStorageServiceV001.loadConversations();
    _messages = ChatStorageServiceV001.loadMessages();
    notifyListeners();
  }

  // Adds a new conversation and persists the updated list.
  void addConversation(Conversation conversation) {
    _conversations.add(conversation);
    ChatStorageServiceV001.saveConversations(_conversations);
    notifyListeners();
  }

  // Adds a new message and updates the corresponding conversation's lastMessageTime.
  void addMessage(Message message) {
    _messages.add(message);
    ChatStorageServiceV001.saveMessages(_messages);

    // Update lastMessageTime for the associated conversation.
    final index = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      final conv = _conversations[index];
      _conversations[index] = Conversation(
        id: conv.id,
        title: conv.title,
        memberIds: conv.memberIds,
        createdAt: conv.createdAt,
        lastMessageTime: message.timestamp,
      );
      ChatStorageServiceV001.saveConversations(_conversations);
    }
    notifyListeners();
  }

  // Removes a conversation and all its messages.
  void removeConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
    ChatStorageServiceV001.saveConversations(_conversations);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
  }

  // Removes a single message by its ID.
  void removeMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    ChatStorageServiceV001.saveMessages(_messages);
    notifyListeners();
  }
}
