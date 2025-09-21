import 'package:flutter/material.dart';

/// Alternative chat list screen for experimenting with different
/// layouts or behaviours.  In this stub it simply displays a
/// placeholder message.
class ChatListScreenV2 extends StatelessWidget {
  const ChatListScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats V2')),
      body: const Center(child: Text('Chat list V2 is empty.')),
    );
  }
}