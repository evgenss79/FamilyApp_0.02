import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../providers/chat_data.dart';
import '../providers/family_data.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatData = Provider.of<ChatDataV001>(context);
    final familyData = Provider.of<FamilyDataV001>(context);
    final conversations = chatData.conversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final messages = chatData.messagesForConversation(conv.id!);
          String subtitle = '';
          if (messages.isNotEmpty) {
            subtitle = messages.last.content;
          }
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
        onPressed: () {
          _createNewConversation(context, chatData, familyData);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewConversation(
      BuildContext context, ChatDataV001 chatData, FamilyDataV001 familyData) {
    final memberIds = familyData.members.map((m) => m.id!).toList();
    final newConv = Conversation(title: 'Family Chat', memberIds: memberIds);
    chatData.addConversation(newConv);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: newConv),
      ),
    );
  }
}
