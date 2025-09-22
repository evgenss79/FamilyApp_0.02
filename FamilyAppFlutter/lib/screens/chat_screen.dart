import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/family_data.dart';

/// Displays a single chat conversation with the ability to send
/// messages via [ChatProvider].
class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  String? _selectedSenderId;

  @override
  void initState() {
    super.initState();
    final memberIds = widget.chat.memberIds.map((id) => id.toString()).toList();
    if (memberIds.isNotEmpty) {
      _selectedSenderId = memberIds.first;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().markRead(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final senderId = _selectedSenderId;
    if (text.isEmpty || senderId == null) return;
    await context
        .read<ChatProvider>()
        .sendText(chatId: widget.chat.id, senderId: senderId, text: text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chat.title)),
      body: Consumer2<ChatProvider, FamilyData>(
        builder: (context, chatProvider, familyData, _) {
          final messages = chatProvider.messagesByChat(widget.chat.id);
          final members = familyData.members;
          if (_selectedSenderId == null) {
            if (widget.chat.memberIds.isNotEmpty) {
              _selectedSenderId = widget.chat.memberIds.first.toString();
            } else if (members.isNotEmpty) {
              _selectedSenderId = members.first.id;
            }
          }

          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(child: Text(context.tr('noMessagesLabel')))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ChatMessage message = messages[index];
                          final senderName =
                              familyData.memberById(message.senderId)?.name ??
                                  context.tr('unknownMemberLabel');
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message.content),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.loc.formatDate(
                                      message.createdAt,
                                      withTime: true,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedSenderId,
                      hint: Text(context.tr('senderLabel')),
                      items: [
                        for (final member in members)
                          DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.name ?? context.tr('noNameLabel')),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSenderId = value);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: context.tr('typeMessageHint'),
                          border: const OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      tooltip: context.tr('sendAction'),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
