import 'package:flutter/material.dart';

import '../models/chat.dart';

/// An alternative chat screen used for testing new layouts or features.
/// This stub displays only the chat title and a placeholder message.
class ChatScreenNew extends StatelessWidget {
  final Chat chat;

  const ChatScreenNew({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${chat.title} (new)')),
      body: const Center(child: Text('Chat screen new has no content.')),
    );
  }
}