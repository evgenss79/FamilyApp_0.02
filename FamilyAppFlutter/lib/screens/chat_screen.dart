import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/family_member.dart';
import '../providers/chat_data.dart';
import '../providers/family_data.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatData = Provider.of<ChatDataV001>(context);
    final familyData = Provider.of<FamilyDataV001>(context);
    final messages = chatData.messagesForConversation(widget.conversation.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final sender = familyData.members.firstWhere(
                  (m) => m.id == msg.senderId,
                  orElse: () => FamilyMember(id: '', name: 'Unknown', relationship: 'Unknown'),
             
                );
                final senderName = sender.name;
                return ListTile(
                  title: Text(senderName),
                  subtitle: Text(msg.content),
                  trailing: Text(_formatTimestamp(msg.timestamp)),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      final currentUserId = familyData.members.isNotEmpty
                          ? familyData.members.first.id!
                          : '';
                      final message = Message(
                        conversationId: widget.conversation.id!,
                        senderId: currentUserId,
                        content: text,
                        timestamp: DateTime.now(),
                      );
                      chatData.addMessage(message);
                      _controller.clear();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
