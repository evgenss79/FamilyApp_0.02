import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Экран добавления нового члена семьи.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  DateTime? _birthday;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final newMember = FamilyMember(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        birthday: _birthday,
      );
      // Вызов провайдера для добавления нового участника.
      Provider.of<FamilyData>(context, listen: false).addMember(newMember);
      // Закрываем экран после сохранения.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a relationship'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_birthday == null
                    ? 'No birthday selected'
                    : 'Birthday: ${_birthday!.toLocal().toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickBirthday,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
