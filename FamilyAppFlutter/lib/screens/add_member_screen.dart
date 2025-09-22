import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Screen for adding or editing a family member.  Provides a detailed
/// form so contact information and other metadata can be captured.
class AddMemberScreen extends StatefulWidget {
  final FamilyMember? initialMember;
  const AddMemberScreen({super.key, this.initialMember});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _documentsController = TextEditingController();

  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    final member = widget.initialMember;
    if (member != null) {
      _nameController.text = member.name ?? '';
      _relationshipController.text = member.relationship ?? '';
      _phoneController.text = member.phone ?? '';
      _emailController.text = member.email ?? '';
      _avatarUrlController.text = member.avatarUrl ?? '';
      _socialMediaController.text = member.socialMedia ?? '';
      _hobbiesController.text = member.hobbies ?? '';
      _documentsController.text = member.documents ?? '';
      _birthday = member.birthday;
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _birthday ?? DateTime(now.year - 10, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) {
      setState(() {
        _birthday = date;
      });
    }
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameController.text.trim();
    final relationship = _relationshipController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final avatarUrl = _avatarUrlController.text.trim();
    final socialMedia = _socialMediaController.text.trim();
    final hobbies = _hobbiesController.text.trim();
    final documents = _documentsController.text.trim();

    final existing = widget.initialMember;
    final member = FamilyMember(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship.isEmpty ? null : relationship,
      birthday: _birthday,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
      socialMedia: socialMedia.isEmpty ? null : socialMedia,
      hobbies: hobbies.isEmpty ? null : hobbies,
      documents: documents.isEmpty ? null : documents,
      documentsList: existing?.documentsList,
      socialNetworks: existing?.socialNetworks,
      messengers: existing?.messengers,
    );

    final familyData = Provider.of<FamilyData>(context, listen: false);
    if (existing == null) {
      familyData.addMember(member);
    } else {
      familyData.updateMember(member);
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _avatarUrlController.dispose();
    _socialMediaController.dispose();
    _hobbiesController.dispose();
    _documentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMember != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Member' : 'Add Member')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthday == null
                            ? 'Birthday not set'
                            : 'Birthday: ${DateFormat('dd.MM.yyyy').format(_birthday!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickBirthday,
                      icon: const Icon(Icons.cake_outlined),
                      label: const Text('Select date'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text('Contacts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(labelText: 'Avatar URL'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _socialMediaController,
                  decoration: const InputDecoration(labelText: 'Social networks'),
                ),
                const Divider(height: 32),
                Text('Additional info', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Hobbies',
                    hintText: 'e.g. football, painting',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentsController,
                  decoration: const InputDecoration(
                    labelText: 'Important documents',
                    hintText: 'Passport, insurance, etc.',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(isEditing ? 'Save changes' : 'Add member'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
