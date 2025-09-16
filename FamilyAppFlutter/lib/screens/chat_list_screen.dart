import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../providers/chat_data.dart';
import '../providers/family_data.dart';
import 'chat_screen.dart';

/// Displays the list of chat conversations and provides a button
/// for creating a new family chat. Each list tile shows the
/// conversation title and the most recent message if available.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatData = Provider.of<ChatDataV001>(context);
    final familyData = Provider.of<FamilyDataV001>(context);
    final conversations = chatData.conversations;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final messages = chatData.messagesForConversation(conv.id);
          final subtitle = messages.isNotEmpty ? messages.last.content : '';
          return ListTile(
            title: Text(conv.title),
            subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conversation: conv),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewConversation(context, chatData, familyData),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewConversation(
    BuildContext context,
    ChatDataV001 chatData,
    FamilyDataV001 familyData,
  ) {
    final memberIds = familyData.members.map((m) => m.id).toList();
    final uuid = const Uuid();
    final newConv = Conversation(
      id: uuid.v4(),
      title: 'Family Chat',
      memberIds: memberIds,
      createdAt: DateTime.now(),
      lastMessageTime: null,
    );
    chatData.addConversation(newConv);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: newConv),
      ),
    );
  }
}
