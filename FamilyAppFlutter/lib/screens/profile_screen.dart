import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/auth_provider.dart';
import '../providers/family_data.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String routeName = 'ProfileScreen';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _avatarUrl;
  String? _avatarStoragePath;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final FamilyMember? member =
        Provider.of<AuthProvider>(context, listen: false).currentMember;
    if (member != null) {
      _nameController.text = member.name ?? '';
      _relationshipController.text = member.relationship ?? '';
      _phoneController.text = member.phone ?? '';
      _emailController.text = member.email ?? '';
      _hobbiesController.text = member.hobbies ?? '';
      _avatarUrl = member.avatarUrl;
      _avatarStoragePath = member.avatarStoragePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final StorageService storage = context.read<StorageService>();
    final String? familyId = auth.familyId;
    if (familyId == null) return;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() {
      _uploadingAvatar = true;
    });
    try {
      final StorageUploadResult result = await storage.uploadMemberAvatar(
        familyId: familyId,
        file: File(file.path),
      );
      if (_avatarStoragePath != null && _avatarStoragePath!.isNotEmpty) {
        // ANDROID-ONLY FIX: clean up the previous Android avatar blob to avoid leaks.
        await storage.deleteByPath(_avatarStoragePath!);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarUrl = result.downloadUrl;
        _avatarStoragePath = result.storagePath;
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final AuthProvider auth = context.read<AuthProvider>();
    final FamilyMember? member = auth.currentMember;
    final String? familyId = auth.familyId;
    if (member == null || familyId == null) {
      return;
    }

    final FamilyMember updated = member.copyWith(
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim().isEmpty
          ? null
          : _relationshipController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? member.email
          : _emailController.text.trim(),
      hobbies: _hobbiesController.text.trim().isEmpty
          ? null
          : _hobbiesController.text.trim(),
      avatarUrl: _avatarUrl,
      avatarStoragePath: _avatarStoragePath,
      updatedAt: DateTime.now().toUtc(),
    );

    await context.read<FamilyData>().updateMember(updated);
    auth.updateCurrentMember(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('profileSavedMessage'))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final FamilyMember? member = auth.currentMember;
    final AppLocalizations loc = context.loc;

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.tr('profileMenuTitle'))),
        body: Center(child: Text(loc.tr('profileMissing'))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.tr('profileMenuTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.indigo.shade50,
                      backgroundImage:
                          _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Text(
                              _initials(
                                  member.name ?? loc.tr('profileMenuTitle')),
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: ElevatedButton(
                        onPressed: _uploadingAvatar ? null : _pickAvatar,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: _uploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: loc.tr('displayNameLabel')),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return loc.tr('displayNameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationshipController,
                decoration: InputDecoration(labelText: loc.tr('relationshipLabel')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: loc.tr('phoneLabel')),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: loc.tr('emailLabel')),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hobbiesController,
                decoration: InputDecoration(labelText: loc.tr('hobbiesLabel')),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _uploadingAvatar ? null : _save,
                child: Text(loc.tr('saveProfileButton')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final List<String> parts = trimmed
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return trimmed[0].toUpperCase();
  }
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  final String first = parts[0][0].toUpperCase();
  final String second = parts[1][0].toUpperCase();
  return '$first$second';
}
