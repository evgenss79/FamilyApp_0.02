import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../providers/family_data.dart';
import 'add_chat_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('chats'))),
      body: Consumer2<ChatProvider, FamilyData>(
        builder: (BuildContext context, ChatProvider chatProvider,
            FamilyData familyData, _) {
          final List<Conversation> conversations = chatProvider.conversations;
          if (chatProvider.isLoading && conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (conversations.isEmpty) {
            return Center(child: Text(context.tr('noChatsLabel')));
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (BuildContext context, int index) {
              final Conversation conversation = conversations[index];
              final String participantNames = conversation.participantIds
                  .map(
                    (String id) =>
                        familyData.findMemberById(id)?.name ??
                            context.tr('unknownMemberLabel'),
                  )
                  .join(', ');
              final String subtitle = conversation.lastMessagePreview?.isNotEmpty == true
                  ? conversation.lastMessagePreview!
                  : context.loc.translateWithParams(
                      'participantsListLabel',
                      {'names': participantNames},
                    );
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(conversation.title ?? context.tr('appTitle')),
                subtitle: Text(subtitle),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.tr('deleteChatAction'),
                  onPressed: () async {
                    await chatProvider.deleteConversation(conversation.id);
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(conversation: conversation),
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
        tooltip: context.tr('createChatTitle'),
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}
