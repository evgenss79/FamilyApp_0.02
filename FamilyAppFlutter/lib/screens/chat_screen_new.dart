import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

/// Screen displaying messages within a chat and allowing sending text and attachments.
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const ChatScreen({Key? key, required this.chatId, required this.chatTitle})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _myId = 'me';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().markRead(widget.chatId));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (_, provider, __) {
      final messages = provider.messagesByChat(widget.chatId);
      return Scaffold(
        appBar: AppBar(title: Text(widget.chatTitle)),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isMine = m.senderId == _myId;

                  Widget bubble;
                  switch (m.type) {
                    case MessageType.text:
                      bubble = Text(m.content);
                      break;
                    case MessageType.image:
                      bubble = _imageBubble(m.content);
                      break;
                    case MessageType.file:
                      bubble = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          Flexible(child: Text(m.content.split('/').last)),
                        ],
                      );
                      break;
                  }

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bubble,
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(m.createdAt),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Photo',
                    icon: const Icon(Icons.photo),
                    onPressed: () async {
                      final picked = await FilePicker.platform.pickFiles(
                          type: FileType.image, allowMultiple: false);
                      if (picked != null && picked.files.single.path != null) {
                        await context.read<ChatProvider>().sendAttachment(
                              chatId: widget.chatId,
                              senderId: _myId,
                              localPath: picked.files.single.path!,
                              type: MessageType.image,
                            );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'File',
                    icon: const Icon(Icons.attach_file),
                    onPressed: () async {
                      final picked = await FilePicker.platform.pickFiles(
                          type: FileType.any, allowMultiple: false);
                      if (picked != null && picked.files.single.path != null) {
                        await context.read<ChatProvider>().sendAttachment(
                              chatId: widget.chatId,
                              senderId: _myId,
                              localPath: picked.files.single.path!,
                              type: MessageType.file,
                            );
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      _controller.clear();
                      await context.read<ChatProvider>().sendText(
                            chatId: widget.chatId,
                            senderId: _myId,
                            text: text,
                          );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _imageBubble(String path) {
    final file = File(path);
    return file.existsSync()
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, width: 180),
          )
        : Text('File unavailable: $path');
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
