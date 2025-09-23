import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../providers/family_data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedSenderId;

  @override
  void initState() {
    super.initState();
    if (widget.conversation.participantIds.isNotEmpty) {
      _selectedSenderId = widget.conversation.participantIds.first;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ChatProvider>()
          .markConversationRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    final String? senderId = _selectedSenderId;
    if (text.isEmpty || senderId == null) {
      return;
    }
    await context.read<ChatProvider>().sendText(
          conversationId: widget.conversation.id,
          senderId: senderId,
          text: text,
        );
    _messageController.clear();
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message,
    String senderName,
  ) {
    final ThemeData theme = Theme.of(context);
    final String content = message.text ??
        (message.type == MessageType.image
            ? '📷 Image'
            : '📎 Attachment');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(content),
            if (message.openData['attachments'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Attachment',
                style: theme.textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              context.loc.formatDate(message.createdAt, withTime: true),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.title ?? context.tr('appTitle'))),
      body: Consumer2<ChatProvider, FamilyData>(
        builder: (BuildContext context, ChatProvider chatProvider,
            FamilyData familyData, _) {
          final List<Message> messages =
              chatProvider.messagesFor(widget.conversation.id);
          final members = familyData.members;
          if (_selectedSenderId == null) {
            if (widget.conversation.participantIds.isNotEmpty) {
              _selectedSenderId = widget.conversation.participantIds.first;
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
                        itemBuilder: (BuildContext context, int index) {
                          final Message message = messages[index];
                          final String senderName = familyData
                                  .memberById(message.senderId)
                                  ?.name ??
                              context.tr('unknownMemberLabel');
                          return _buildMessageBubble(
                            context,
                            message,
                            senderName,
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
                            child:
                                Text(member.name ?? context.tr('noNameLabel')),
                          ),
                      ],
                      onChanged: (String? value) {
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
