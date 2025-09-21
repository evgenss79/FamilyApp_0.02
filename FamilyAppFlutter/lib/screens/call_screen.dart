import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/family_data.dart';
import '../models/family_member.dart';

/// Screen that displays an in-progress audio or video call.
class CallScreen extends StatelessWidget {
  final Conversation conversation;
  final String callType; // 'audio' or 'video'

  const CallScreen({
    Key? key,
    required this.conversation,
    required this.callType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final familyData = Provider.of<FamilyData>(context, listen: false);
    final participants = conversation.memberIds
        .map((id) => familyData.members.firstWhere(
              (member) => member.id == id,
              orElse: () => FamilyMember(id: '', name: 'Unknown'),
            ))
        .toList();

    final callTypeLabel =
        callType.isNotEmpty ? '${callType[0].toUpperCase()}${callType.substring(1)}' : '';

    return Scaffold(
      appBar: AppBar(title: Text('$callTypeLabel Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Calling ${participants.map((m) => m.name).join(', ')}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text('Call in progress...', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.call_end),
              label: const Text('End Call'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}