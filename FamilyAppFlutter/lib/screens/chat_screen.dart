import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/message_type.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _sendingAttachment = false;

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

  Future<void> _pickImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    final String? senderId = _selectedSenderId;
    if (picked == null || senderId == null) {
      return;
    }
    await _sendAttachment(picked.path, MessageType.image);
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    final String? path = result?.files.single.path;
    final String? senderId = _selectedSenderId;
    if (path == null || senderId == null) {
      return;
    }
    await _sendAttachment(path, MessageType.file);
  }

  Future<void> _sendAttachment(String path, MessageType type) async {
    final String? senderId = _selectedSenderId;
    if (senderId == null) {
      return;
    }
    setState(() {
      _sendingAttachment = true;
    });
    try {
      await context.read<ChatProvider>().sendAttachment(
            chatId: widget.chat.id,
            senderId: senderId,
            localPath: path,
            type: type,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('attachmentSendError'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingAttachment = false;
        });
      }
    }
  }

  Future<void> _openAttachment(String url) async {
    if (url.isEmpty) {
      return;
    }
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('attachmentOpenError'))),
      );
    }
  }

  Widget _buildMessageContent(BuildContext context, ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.content);
      case MessageType.image:
        return GestureDetector(
          onTap: () => _openAttachment(message.content),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                context.tr('attachmentOpenError'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        );
      case MessageType.file:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => _openAttachment(message.content),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.tr('openAttachmentAction')),
            ),
            SelectableText(
              message.content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
    }
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
                                    .withValues(alpha: 0.1),
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
                                  _buildMessageContent(context, message),
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
              if (_sendingAttachment)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(context.tr('uploadingAttachmentLabel')),
                    ],
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
                    IconButton(
                      icon: const Icon(Icons.photo),
                      tooltip: context.tr('attachImageAction'),
                      onPressed: _sendingAttachment ? null : _pickImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: context.tr('attachFileAction'),
                      onPressed: _sendingAttachment ? null : _pickFile,
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
                      onPressed: _sendingAttachment ? null : _sendMessage,
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
