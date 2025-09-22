import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'call_screen.dart';

class CallSetupScreen extends StatefulWidget {
  const CallSetupScreen({super.key});

  @override
  State<CallSetupScreen> createState() => _CallSetupScreenState();
}

class _CallSetupScreenState extends State<CallSetupScreen> {
  final _titleController = TextEditingController(text: 'Family call');
  String _callType = 'audio';
  final Set<String> _selectedMemberIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startCall(List<FamilyMember> members) {
    final selected = _selectedMemberIds.isNotEmpty
        ? _selectedMemberIds.toList()
        : members.map((member) => member.id).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant.')),
      );
      return;
    }
    final title = _titleController.text.trim().isEmpty
        ? 'Call'
        : _titleController.text.trim();
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      memberIds: selected,
      createdAt: DateTime.now(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          conversation: conversation,
          callType: _callType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyData>().members;
    return Scaffold(
      appBar: AppBar(title: const Text('Start a call')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Call title'),
            ),
            const SizedBox(height: 16),
            Text('Call type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'audio', label: Text('Audio'), icon: Icon(Icons.call)),
                ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam)),
              ],
              selected: <String>{_callType},
              onSelectionChanged: (selection) {
                setState(() => _callType = selection.first);
              },
            ),
            const SizedBox(height: 24),
            Text('Participants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Text('Add family members to start a call.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final member in members)
                    FilterChip(
                      label: Text(member.name ?? 'Unnamed'),
                      selected: _selectedMemberIds.contains(member.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMemberIds.add(member.id);
                          } else {
                            _selectedMemberIds.remove(member.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startCall(members),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start call'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
