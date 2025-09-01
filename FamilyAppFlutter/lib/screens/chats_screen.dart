import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import 'chat_screen_new.dart';
import '../services/call_service.dart';
import '../services/cloud_call_service.dart';
import 'cloud_call_screen.dart';

/// Displays a list of chats and allows navigation to chat details and calls.
class ChatsScreen extends StatelessWidget {
  static const routeName = '/chats';

  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (_, chatProvider, __) {
      final chats = chatProvider.chats;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Chats'),
          actions: [
            IconButton(
              tooltip: 'Local test call',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _LocalCallScreen()),
                );
              },
              icon: const Icon(Icons.video_call),
            ),
            IconButton(
              tooltip: 'Cloud call (room)',
              onPressed: () {
                Navigator.of(context).pushNamed(CloudCallScreen.routeName);
              },
              icon: const Icon(Icons.cloud),
            ),
          ],
        ),
        body: ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              title: Text(chat.title),
              subtitle: Text(chat.lastMessagePreview ?? 'No messages'),
              trailing: Text(
                _formatTime(chat.updatedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chat.id,
                      chatTitle: chat.title,
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final titleController = TextEditingController();
            final membersController =
                TextEditingController(text: 'me, spouse, child');
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('New chat'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: membersController,
                      decoration: const InputDecoration(
                        labelText: 'Members (comma separated)',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final title = titleController.text.trim().isEmpty
                          ? 'New chat'
                          : titleController.text.trim();
                      final members = membersController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      await chatProvider.createChat(
                        title: title,
                        memberIds: members,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            );
          },
          label: const Text('New chat'),
          icon: const Icon(Icons.add_comment),
        ),
      );
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// A wrapper to present the local call screen using CallService.
class _LocalCallScreen extends StatefulWidget {
  const _LocalCallScreen();

  @override
  State<_LocalCallScreen> createState() => _LocalCallScreenState();
}

class _LocalCallScreenState extends State<_LocalCallScreen> {
  final _call = CallService();

  @override
  void initState() {
    super.initState();
    _call.init();
  }

  @override
  void dispose() {
    _call.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local test call')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _call.ready,
                    builder: (_, ready, __) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        color: Colors.black12,
                        child: ready
                            ? RTCVideoViewWrapper(
                                renderer: _call.localRenderer,
                                label: 'Local',
                              )
                            : const Center(child: Text('Video unavailable')),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: RTCVideoViewWrapper(
                        renderer: _call.remoteRenderer, label: 'Remote'),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _call.startLoopback(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start loopback'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () => _call.toggleMute(),
                    icon: const Icon(Icons.mic_off),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () => _call.switchCamera(),
                    icon: const Icon(Icons.cameraswitch),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () => _call.hangup(),
                    icon: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
