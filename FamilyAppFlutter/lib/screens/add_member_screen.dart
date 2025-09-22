import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import '../services/storage_service.dart';

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
  final _socialMediaController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _documentsController = TextEditingController();

  final List<_SelectEntry> _documentEntries = [];
  final List<_SelectEntry> _socialEntries = [];
  final List<_SelectEntry> _messengerEntries = [];

  String? _avatarUrl;
  String? _avatarStoragePath;
  String? _avatarFileName;
  bool _uploadingAvatar = false;

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
      _avatarUrl = member.avatarUrl;
      _avatarStoragePath = member.avatarStoragePath;
      _socialMediaController.text = member.socialMedia ?? '';
      _hobbiesController.text = member.hobbies ?? '';
      _documentsController.text = member.documents ?? '';
      _birthday = member.birthday;
      final docs = member.documentsList ?? const <Map<String, String>>[];
      if (docs.isEmpty) {
        _documentEntries.add(_SelectEntry(type: _documentOptions.first));
      } else {
        for (final doc in docs) {
          _documentEntries.add(
            _SelectEntry(
              type: _detectType(doc['type'], _documentOptions),
              initialValue: doc['value'] ?? doc['description'] ?? '',
            ),
          );
        }
      }
      final socials = member.socialNetworks ?? const <Map<String, String>>[];
      if (socials.isEmpty) {
        _socialEntries.add(_SelectEntry(type: _socialOptions.first));
      } else {
        for (final net in socials) {
          _socialEntries.add(
            _SelectEntry(
              type: _detectType(net['type'], _socialOptions),
              initialValue: net['value'] ?? net['handle'] ?? '',
            ),
          );
        }
      }
      final messengers = member.messengers ?? const <Map<String, String>>[];
      if (messengers.isEmpty) {
        _messengerEntries.add(_SelectEntry(type: _messengerOptions.first));
      } else {
        for (final messenger in messengers) {
          _messengerEntries.add(
            _SelectEntry(
              type: _detectType(messenger['type'], _messengerOptions),
              initialValue: messenger['value'] ?? messenger['handle'] ?? '',
            ),
          );
        }
      }
    }
    if (_documentEntries.isEmpty) {
      _documentEntries.add(_SelectEntry(type: _documentOptions.first));
    }
    if (_socialEntries.isEmpty) {
      _socialEntries.add(_SelectEntry(type: _socialOptions.first));
    }
    if (_messengerEntries.isEmpty) {
      _messengerEntries.add(_SelectEntry(type: _messengerOptions.first));
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

  Future<void> _pickAvatar() async {
    final storage = context.read<StorageService>();
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    setState(() {
      _uploadingAvatar = true;
    });
    try {
      final upload = await storage.uploadMemberAvatar(
        familyId: AppConfig.familyId,
        file: file,
      );
      if (_avatarStoragePath != null &&
          _avatarStoragePath!.isNotEmpty &&
          _avatarStoragePath != upload.storagePath) {
        await storage.deleteByPath(_avatarStoragePath!);
      }
      setState(() {
        _avatarUrl = upload.downloadUrl;
        _avatarStoragePath = upload.storagePath;
        _avatarFileName = result.files.single.name;
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameController.text.trim();
    final relationship = _relationshipController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final socialMedia = _socialMediaController.text.trim();
    final hobbies = _hobbiesController.text.trim();
    final documents = _documentsController.text.trim();

    final documentsList = _documentEntries
        .map((entry) => entry.toMap())
        .whereType<Map<String, String>>()
        .toList();
    final socials = _socialEntries
        .map((entry) => entry.toMap())
        .whereType<Map<String, String>>()
        .toList();
    final messengers = _messengerEntries
        .map((entry) => entry.toMap())
        .whereType<Map<String, String>>()
        .toList();

    final existing = widget.initialMember;
    final member = FamilyMember(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship.isEmpty ? null : relationship,
      birthday: _birthday,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
      avatarUrl: _avatarUrl,
      avatarStoragePath: _avatarStoragePath,
      socialMedia: socialMedia.isEmpty ? null : socialMedia,
      hobbies: hobbies.isEmpty ? null : hobbies,
      documents: documents.isEmpty ? null : documents,
      documentsList: documentsList.isEmpty ? null : documentsList,
      socialNetworks: socials.isEmpty ? null : socials,
      messengers: messengers.isEmpty ? null : messengers,
    );

    final familyData = Provider.of<FamilyData>(context, listen: false);
    if (existing == null) {
      await familyData.addMember(member);
    } else {
      await familyData.updateMember(member);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _socialMediaController.dispose();
    _hobbiesController.dispose();
    _documentsController.dispose();
    for (final entry in _documentEntries) {
      entry.dispose();
    }
    for (final entry in _socialEntries) {
      entry.dispose();
    }
    for (final entry in _messengerEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMember != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? context.tr('editMember') : context.tr('addMember'),
        ),
      ),
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
                  decoration: InputDecoration(labelText: context.tr('fieldName')),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('validationEnterName');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _relationshipController,
                  decoration: InputDecoration(labelText: context.tr('fieldRelationship')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthday == null
                            ? context.tr('birthdayNotSet')
                            : context.loc.birthdayLabel(_birthday!),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickBirthday,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(context.tr('selectDate')),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(context.tr('contactsSection'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: context.tr('fieldPhone')),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: context.tr('fieldEmail')),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(_avatarFileName ?? context.tr('avatarNotSelected')),
                        subtitle: _uploadingAvatar
                            ? Text(context.tr('avatarUploading'))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _uploadingAvatar ? null : _pickAvatar,
                      icon: const Icon(Icons.upload),
                      label: Text(context.tr('selectAvatar')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _socialMediaController,
                  decoration: InputDecoration(labelText: context.tr('socialSummaryLabel')),
                  maxLines: 2,
                ),
                const Divider(height: 32),
                Text(context.tr('additionalInfoSection'),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hobbiesController,
                  decoration: InputDecoration(
                    labelText: context.tr('fieldHobbies'),
                    hintText: context.tr('hobbiesHint'),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentsController,
                  decoration: InputDecoration(
                    labelText: context.tr('documentsSummaryLabel'),
                    hintText: context.tr('documentsHint'),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: context.tr('documentsSection')),
                ..._buildSelectEntries(
                  context,
                  entries: _documentEntries,
                  options: _documentOptions,
                  labelBuilder: (ctx, key) => ctx.tr('documentType.$key'),
                  valueLabel: context.tr('documentValueLabel'),
                  onAdd: () => setState(() {
                    _documentEntries.add(
                      _SelectEntry(type: _documentOptions.first),
                    );
                  }),
                  onRemove: (index) => setState(() {
                    if (_documentEntries.length > 1) {
                      final removed = _documentEntries.removeAt(index);
                      removed.dispose();
                    }
                  }),
                  addLabel: context.tr('addDocumentEntry'),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: context.tr('socialNetworksSection')),
                ..._buildSelectEntries(
                  context,
                  entries: _socialEntries,
                  options: _socialOptions,
                  labelBuilder: (ctx, key) => ctx.tr('socialNetwork.$key'),
                  valueLabel: context.tr('socialValueLabel'),
                  onAdd: () => setState(() {
                    _socialEntries.add(
                      _SelectEntry(type: _socialOptions.first),
                    );
                  }),
                  onRemove: (index) => setState(() {
                    if (_socialEntries.length > 1) {
                      final removed = _socialEntries.removeAt(index);
                      removed.dispose();
                    }
                  }),
                  addLabel: context.tr('addSocialEntry'),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: context.tr('messengersSection')),
                ..._buildSelectEntries(
                  context,
                  entries: _messengerEntries,
                  options: _messengerOptions,
                  labelBuilder: (ctx, key) => ctx.tr('messenger.$key'),
                  valueLabel: context.tr('messengerValueLabel'),
                  onAdd: () => setState(() {
                    _messengerEntries.add(
                      _SelectEntry(type: _messengerOptions.first),
                    );
                  }),
                  onRemove: (index) => setState(() {
                    if (_messengerEntries.length > 1) {
                      final removed = _messengerEntries.removeAt(index);
                      removed.dispose();
                    }
                  }),
                  addLabel: context.tr('addMessengerEntry'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEditing
                          ? context.tr('saveChanges')
                          : context.tr('addMember'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectEntries(
    BuildContext context, {
    required List<_SelectEntry> entries,
    required List<String> options,
    required String Function(BuildContext, String) labelBuilder,
    required String valueLabel,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
    required String addLabel,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(

                  initialValue: entry.type ?? options.first,

                  items: [
                    for (final option in options)
                      DropdownMenuItem<String>(
                        value: option,
                        child: Text(labelBuilder(context, option)),
                      ),
                  ],
                  onChanged: (value) => setState(() => entry.type = value),
                  decoration: InputDecoration(
                    labelText: labelBuilder(context, entry.type ?? options.first),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: valueLabel),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    children.add(
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
      ),
    );
    return children;
  }

  String _detectType(String? value, List<String> options) {
    if (value == null || value.isEmpty) return options.last;
    if (options.contains(value)) return value;
    final normalized = value.toLowerCase();
    for (final option in options) {
      if (option == 'other') continue;
      if (normalized.contains(option.toLowerCase())) return option;
    }
    return options.last;
  }

  static const List<String> _documentOptions = <String>[
    'passport',
    'driverLicense',
    'birthCertificate',
    'insurancePolicy',
    'idCard',
    'other',
  ];

  static const List<String> _socialOptions = <String>[
    'facebook',
    'instagram',
    'vk',
    'linkedin',
    'tiktok',
    'youtube',
    'twitter',
    'other',
  ];

  static const List<String> _messengerOptions = <String>[
    'whatsapp',
    'telegram',
    'signal',
    'viber',
    'wechat',
    'messenger',
    'line',
    'skype',
    'other',
  ];
}

class _SelectEntry {
  _SelectEntry({this.type, String? initialValue})
      : value = TextEditingController(text: initialValue ?? '');

  String? type;
  final TextEditingController value;

  Map<String, String>? toMap() {
    final typeKey = type;
    final trimmed = value.text.trim();
    if (typeKey == null || typeKey.isEmpty || trimmed.isEmpty) {
      return null;
    }
    return {'type': typeKey, 'value': trimmed};
  }

  void dispose() => value.dispose();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
