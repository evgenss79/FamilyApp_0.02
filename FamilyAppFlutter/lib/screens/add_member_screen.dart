import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

/// A screen for adding or editing a family member. It handles
/// collecting basic details like name, relationship, birthday,
/// phone, email, hobbies, documents, social networks, and messengers.
/// It also allows picking and uploading an avatar image to Firebase
/// Storage and storing its URL.
class AddMemberScreenV001 extends StatefulWidget {
  /// Optionally pass an existing [FamilyMember] to edit.  If null, the
  /// form will create a new member when saved.
  final FamilyMember? member;

  const AddMemberScreenV001({Key? key, this.member}) : super(key: key);

  @override
  State<AddMemberScreenV001> createState() => _AddMemberScreenV001State();
}

class _AddMemberScreenV001State extends State<AddMemberScreenV001> {
  final _formKey = GlobalKey<FormState>();

  // Basic text controllers
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _hobbiesController = TextEditingController();

  // Image picker and file for avatar
  final ImagePicker _imagePicker = ImagePicker();
  File? _avatarFile;

  // Structured lists for documents, social networks and messengers.
  List<Map<String, String>> _documentEntries = [];
  List<Map<String, String>> _socialEntries = [];
  List<Map<String, String>> _messengerEntries = [];

  DateTime? _birthday;

  // Predefined types for dropdowns.
  final List<String> _documentTypes = [
    'Passport',
    'ID',
    'Driver License',
    'Birth Certificate',
    'Insurance Card',
    'Other',
  ];
  final List<String> _socialTypes = [
    'Instagram',
    'Facebook',
    'Discord',
    'LinkedIn',
    'Twitter',
    'TikTok',
    'Other',
  ];
  final List<String> _messengerTypes = [
    'WhatsApp',
    'Telegram',
    'Viber',
    'WeChat',
    'Signal',
    'Skype',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      // Prefill controllers and lists from the existing member.
      _nameController.text = member.name;
      _relationshipController.text = member.relationship;
      _phoneController.text = member.phone ?? '';
      _avatarUrlController.text = member.avatarUrl ?? '';
      _emailController.text = member.email ?? '';
      _hobbiesController.text = member.hobbies ?? '';
      _birthday = member.birthday;
      // Convert structured fields.
      if (member.documentsList != null) {
        _documentEntries = member.documentsList!
            .map<Map<String, String>>((e) => {
                  'type': e['type'] ?? 'Other',
                  'value': e['value'] ?? '',
                })
            .toList();
      } else if (member.documents != null && member.documents!.isNotEmpty) {
        // Legacy single string becomes one entry of type Other.
        _documentEntries = [
          {'type': 'Other', 'value': member.documents!},
        ];
      }
      if (member.socialNetworks != null) {
        _socialEntries = member.socialNetworks!
            .map<Map<String, String>>((e) => {
                  'type': e['type'] ?? 'Other',
                  'value': e['value'] ?? '',
                })
            .toList();
      } else if (member.socialMedia != null && member.socialMedia!.isNotEmpty) {
        _socialEntries = [
          {'type': 'Other', 'value': member.socialMedia!},
        ];
      }
      if (member.messengers != null) {
        _messengerEntries = member.messengers!
            .map<Map<String, String>>((e) => {
                  'type': e['type'] ?? 'Other',
                  'value': e['value'] ?? '',
                })
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _emailController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  /// Pick a birthday using a date picker dialog.
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

  /// Pick an avatar from gallery and upload it to Firebase Storage.
  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      // Cache the previous avatar URL so we can delete it after a successful upload.
      final oldUrl = _avatarUrlController.text.trim();
      setState(() {
        _avatarFile = file;
      });
      try {
        // Generate a new storage reference for the uploaded image.
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${const Uuid().v4()}.jpg');
        // Upload the new avatar file.
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        // If there was a previous avatar URL and it differs from the new one,
        // attempt to remove the old file from Firebase Storage to avoid orphaned files.
        if (oldUrl.isNotEmpty && oldUrl != url) {
          try {
            await FirebaseStorage.instance.refFromURL(oldUrl).delete();
          } catch (e) {
            debugPrint('Error deleting old avatar: $e');
          }
        }
        setState(() {
          _avatarUrlController.text = url;
        });
      } catch (e) {
        // In a real app, you'd show an error to the user.
        debugPrint('Error uploading avatar: $e');
      }
    }
  }

  /// Save the member details, either updating an existing member or adding a new one.
  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final id = widget.member?.id ?? const Uuid().v4();
    final newMember = FamilyMember(
      id: id,
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      birthday: _birthday,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      hobbies: _hobbiesController.text.trim().isNotEmpty
          ? _hobbiesController.text.trim()
          : null,
      avatarUrl: _avatarUrlController.text.trim().isNotEmpty
          ? _avatarUrlController.text.trim()
          : null,
      // Legacy fields left null for newly structured entries.
      socialMedia: null,
      documents: null,
      documentsList: _documentEntries.isNotEmpty
          ? List<Map<String, String>>.from(_documentEntries)
          : null,
      socialNetworks: _socialEntries.isNotEmpty
          ? List<Map<String, String>>.from(_socialEntries)
          : null,
      messengers: _messengerEntries.isNotEmpty
          ? List<Map<String, String>>.from(_messengerEntries)
          : null,
    );
    final data = Provider.of<FamilyDataV001>(context, listen: false);
    if (widget.member != null) {
      data.updateMember(newMember);
    } else {
      data.addMember(newMember);
    }
    Navigator.of(context).pop();
  }

  /// Build a row for editing a document/social/messenger entry with dropdown and text field.
  Widget _buildEntryRow(
    List<Map<String, String>> entries,
    int index,
    List<String> types,
    void Function(void Function()) setStateCallback,
  ) {
    final entry = entries[index];
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: entry['type'],
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Type',
            ),
            isExpanded: true,
            items: types
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  entry['type'] = value;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: TextFormField(
            initialValue: entry['value'],
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Value',
            ),
            onChanged: (val) {
              entry['value'] = val;
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                entries.removeAt(index);
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member != null ? 'Edit Member' : 'Add Member'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Name and relationship
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a relationship' : null,
              ),
              // Birthday picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Birthday'),
                subtitle: Text(
                  _birthday != null
                      ? _birthday!.toLocal().toString().split(' ')[0]
                      : 'Select date',
                ),
                onTap: _pickBirthday,
              ),
              const SizedBox(height: 8),
              // Avatar selection and URL
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!) as ImageProvider
                          : (_avatarUrlController.text.trim().isNotEmpty
                              ? NetworkImage(_avatarUrlController.text.trim()) as ImageProvider
                              : null),
                      child: (_avatarFile == null &&
                              _avatarUrlController.text.trim().isEmpty)
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                  ),
                    const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(labelText: 'Avatar URL'),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isNotEmpty) {
                          // Simple URL validation: must start with http or https.
                          if (!v.startsWith('http')) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickAvatar,
                    tooltip: 'Pick from gallery',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contact information section
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Phone field with helper text and validation.
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  helperText: 'Include country code, e.g. +41 79 123 45 67',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isNotEmpty) {
                    // Phone numbers must consist only of digits and may start with a plus sign.
                    final pattern = RegExp(r'^\+?[0-9]{7,15}$');
                    if (!pattern.hasMatch(v)) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              // Email field with helper text and validation.
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Format: name@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isNotEmpty) {
                    // Simple email validation requiring a single @ and a domain.
                    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!pattern.hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              // Hobbies field with helper text indicating comma‑separated entries.
              TextFormField(
                controller: _hobbiesController,
                decoration: const InputDecoration(
                  labelText: 'Hobbies',
                  helperText: 'Separate multiple hobbies with commas',
                ),
              ),
              const SizedBox(height: 16),
              // Documents section
              Text(
                'Documents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _documentEntries.length,
                (i) => _buildEntryRow(_documentEntries, i, _documentTypes, setState),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Document'),
                  onPressed: () {
                    setState(() {
                      _documentEntries.add({'type': _documentTypes.first, 'value': ''});
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Social networks section
              Text(
                'Social Networks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _socialEntries.length,
                (i) => _buildEntryRow(_socialEntries, i, _socialTypes, setState),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Social'),
                  onPressed: () {
                    setState(() {
                      _socialEntries.add({'type': _socialTypes.first, 'value': ''});
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Messengers section
              Text(
                'Messengers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _messengerEntries.length,
                (i) =>
                    _buildEntryRow(_messengerEntries, i, _messengerTypes, setState),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Messenger'),
                  onPressed: () {
                    setState(() {
                      _messengerEntries.add({
                        'type': _messengerTypes.first,
                        'value': '',
                      });
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Save button at the end of the scrollable content
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
