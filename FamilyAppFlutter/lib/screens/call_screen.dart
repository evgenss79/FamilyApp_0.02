import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'package:provider/provider.dart';

/// Screen that displays an in-progress audio or video call.
/// 
/// This is a simple placeholder implementation for call functionality.
/// It shows the list of conversation participants and a button to end the call.
/// The [callType] determines whether the call is audio or video.
class CallScreen extends StatelessWidget {
  /// The conversation for which the call is occurring.
  final Conversation conversation;

  /// The type of call: either 'audio' or 'video'.
  final String callType;

  const CallScreen({
    Key? key,
    required this.conversation,
    required this.callType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final familyData = Provider.of<FamilyDataV001>(context, listen: false);
    // Retrieve participant names from member IDs. Fallback to 'Unknown' if member not found.
    final participants = conversation.memberIds
        .map((id) => familyData.members.firstWhere(
              (member) => member.id == id,
              orElse: () => FamilyMember(id: '', name: 'Unknown, relationship: ''),
            ))
        .toList();

    // Capitalize call type for display.
    final String callTypeLabel =
        callType.isNotEmpty ? callType[0].toUpperCase() + callType.substring(1) : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$callTypeLabel Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the names of participants in the call.
            Text(
              'Calling ${participants.map((m) => m.name).join(', ')}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Call in progress...',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // End call by popping the screen.
                Navigator.of(context).pop();
              },
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
