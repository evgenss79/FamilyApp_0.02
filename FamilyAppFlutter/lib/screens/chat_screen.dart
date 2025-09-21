import 'package:flutter/material.dart';

import '../models/chat.dart';

/// Displays a single chat conversation.  This placeholder implementation
/// shows only the chat title and a message indicating that no
/// messages are present.  Integrate with [ChatProvider] to show
/// messages.
class ChatScreen extends StatelessWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chat.title)),
      body: const Center(child: Text('No messages yet.')),
    );
  }
}