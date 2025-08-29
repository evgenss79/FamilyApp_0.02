import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member_v001.dart';
import '../providers/family_data_v001.dart';

class AddMemberScreenV001 extends StatefulWidget {
  const AddMemberScreenV001({Key? key}) : super(key: key);

  @override
  State<AddMemberScreenV001> createState() => _AddMemberScreenV001State();
}

class _AddMemberScreenV001State extends State<AddMemberScreenV001> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _documentsController = TextEditingController();
  DateTime? _birthday;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _socialMediaController.dispose();
    _hobbiesController.dispose();
    _documentsController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final newMember = FamilyMember(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        birthday: _birthday,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        socialMedia: _socialMediaController.text.trim().isNotEmpty ? _socialMediaController.text.trim() : null,
        hobbies: _hobbiesController.text.trim().isNotEmpty ? _hobbiesController.text.trim() : null,
        documents: _documentsController.text.trim().isNotEmpty ? _documentsController.text.trim() : null,
      );
      Provider.of<FamilyDataV001>(context, listen: false).addMember(newMember);
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
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a relationship' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _socialMediaController,
                decoration: const InputDecoration(labelText: 'Social Media'),
              ),
              TextFormField(
                controller: _hobbiesController,
                decoration: const InputDecoration(labelText: 'Hobbies'),
              ),
              TextFormField(
                controller: _documentsController,
                decoration: const InputDecoration(labelText: 'Documents'),
              ),
              ListTile(
                title: const Text('Birthday'),
                subtitle: Text(_birthday != null ? _birthday!.toLocal().toString().split(' ')[0] : 'Select date'),
                onTap: _pickBirthday,
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
