import 'package:flutter/material.dart';

import '../models/conversation.dart';

class ChatScreenNew extends StatelessWidget {
  const ChatScreenNew({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${conversation.title ?? 'Chat'} (new)')),
      body: const Center(child: Text('Chat screen new has no content.')),
    );
  }
}
