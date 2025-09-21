import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Screen for adding a new family member.  Provides a simple form
/// containing a text field for the name and saves the member via
/// [FamilyData] when submitted.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameController = TextEditingController();

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final member = FamilyMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    Provider.of<FamilyData>(context, listen: false).addMember(member);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}