import 'package:flutter/material.dart';

/// Top-level screen that could show multiple chat-related tabs or
/// categories.  This simplified version displays a single message.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: const Center(child: Text('Chats screen is empty.')),
    );
  }
}