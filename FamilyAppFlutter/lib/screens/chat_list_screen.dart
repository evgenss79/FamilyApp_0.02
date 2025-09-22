import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../providers/family_data.dart';
import 'add_chat_screen.dart';
import 'chat_screen.dart';

/// Displays a list of chat conversations backed by [ChatProvider].
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Consumer2<ChatProvider, FamilyData>(
        builder: (context, chatProvider, familyData, _) {
          final List<Chat> chats = chatProvider.chats;
          if (chats.isEmpty) {
            return const Center(child: Text('No chats available.'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participantNames = chat.memberIds
                  .map((id) => familyData.memberById(id)?.name ?? 'Unknown')
                  .join(', ');
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(chat.title),
                subtitle: Text(
                  chat.lastMessagePreview?.isNotEmpty == true
                      ? chat.lastMessagePreview!
                      : 'Participants: $participantNames',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => chatProvider.deleteChat(chat.id),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chat: chat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddChatScreen()),
          );
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}
