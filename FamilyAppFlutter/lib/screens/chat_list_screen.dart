import 'package:flutter/material.dart';

/// Placeholder screen showing a list of chat conversations.  This
/// simplified version displays static text and can be expanded to
/// integrate with [ChatProvider] or [ChatData].
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: const Center(child: Text('No chats available.')),
    );
  }
}