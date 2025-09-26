import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Screen that displays an in-progress audio or video call.
class CallScreen extends StatelessWidget {
  final Conversation conversation;
  final String callType; // 'audio' or 'video'

  const CallScreen({
    super.key,
    required this.conversation,
    required this.callType,
  });

  @override
  Widget build(BuildContext context) {
    final familyData = Provider.of<FamilyData>(context, listen: false);
    final participants = conversation.participantIds
        .map((id) => familyData.members.firstWhere(
              (member) => member.id == id,
              orElse: () => FamilyMember(
                id: '',
                name: context.tr('unknownMemberLabel'),
              ),
            ))
        .toList();

    final typeLabel =
        callType == 'video' ? context.tr('videoLabel') : context.tr('audioLabel');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.translateWithParams('callScreenTitle', {'type': typeLabel}),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.loc.translateWithParams(
                'callingLabel',
                {
                  'names': participants.map((m) => m.name ?? '').join(', '),
                },
              ),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('callInProgress'),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.call_end),
              label: Text(context.tr('endCallAction')),
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
