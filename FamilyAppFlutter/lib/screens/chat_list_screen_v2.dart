import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../providers/chat_data.dart';
import '../providers/family_data.dart';
import 'chat_screen.dart';

/// An enhanced chat list screen that allows creating a conversation
/// with selected participants. Existing conversations show their
/// latest message.
class ChatListScreenV2 extends StatelessWidget {
  const ChatListScreenV2({Key? key}) : super(key: key);

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
          final messages = chatData.messagesForConversation(conv.id);
          final lastMessage = messages.isNotEmpty ? messages.last.content : '';
          return ListTile(
            title: Text(conv.title),
            subtitle: lastMessage.isNotEmpty ? Text(lastMessage) : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                chatData.removeConversation(conv.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateConversationDialog(context, familyData, chatData);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateConversationDialog(
    BuildContext context,
    FamilyDataV001 familyData,
    ChatDataV001 chatData,
  ) {
    final memberList = familyData.members;
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Participants'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: memberList.map((m) {
                    final isSelected = selectedIds.contains(m.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(m.name),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedIds.add(m.id);
                          } else {
                            selectedIds.remove(m.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedIds.isNotEmpty) {
                      final selectedNames = memberList
                          .where((m) => selectedIds.contains(m.id))
                          .map((m) => m.name)
                          .toList();
                      final convTitle = selectedIds.length == memberList.length
                          ? 'Family Chat'
                          : selectedNames.join(', ');
                      final uuid = const Uuid();
                      final newConv = Conversation(
                        id: uuid.v4(),
                        title: convTitle,
                        memberIds: selectedIds.toList(),
                        createdAt: DateTime.now(),
                        lastMessageTime: null,
                      );
                      chatData.addConversation(newConv);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversation: newConv),
                        ),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
