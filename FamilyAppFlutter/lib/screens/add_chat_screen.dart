import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../providers/chat_provider.dart';
import '../providers/family_data.dart';

class AddChatScreen extends StatefulWidget {
  const AddChatScreen({super.key});

  @override
  State<AddChatScreen> createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final Set<String> _selectedMemberIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant.')),
      );
      return;
    }
    final provider = context.read<ChatProvider>();
    await provider.createChat(
      title: _titleController.text.trim(),
      memberIds: _selectedMemberIds.toList(),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyData>().members;
    return Scaffold(
      appBar: AppBar(title: const Text('Create chat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Chat title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Participants', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (members.isEmpty)
                const Text('Add family members first to create a chat.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final FamilyMember member in members)
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
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Create chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
