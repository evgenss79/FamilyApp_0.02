import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

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
  final _emailController = TextEditingController();
  final _hobbiesController = TextEditingController();

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
      _emailController.text = member.email ?? '';
      _hobbiesController.text = member.hobbies ?? '';
      _birthday = member.birthday;
      // Convert structured fields.
      if (member.documentsList != null) {
        _documentEntries = member.documentsList!
            .map<Map<String, String>>((e) => {'type': e['type'] ?? 'Other', 'value': e['value'] ?? ''})
            .toList();
      } else if (member.documents != null && member.documents!.isNotEmpty) {
        // Legacy single string becomes one entry of type Other.
        _documentEntries = [
          {'type': 'Other', 'value': member.documents!},
        ];
      }
      if (member.socialNetworks != null) {
        _socialEntries = member.socialNetworks!
            .map<Map<String, String>>((e) => {'type': e['type'] ?? 'Other', 'value': e['value'] ?? ''})
            .toList();
      } else if (member.socialMedia != null && member.socialMedia!.isNotEmpty) {
        _socialEntries = [
          {'type': 'Other', 'value': member.socialMedia!},
        ];
      }
      if (member.messengers != null) {
        _messengerEntries = member.messengers!
            .map<Map<String, String>>((e) => {'type': e['type'] ?? 'Other', 'value': e['value'] ?? ''})
            .toList();
      }
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final id = widget.member?.id ?? const Uuid().v4();
    final newMember = FamilyMember(
      id: id,
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      birthday: _birthday,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      hobbies: _hobbiesController.text.trim().isNotEmpty ? _hobbiesController.text.trim() : null,
      // Legacy fields left null for newly structured entries.
      socialMedia: null,
      documents: null,
      documentsList: _documentEntries.isNotEmpty ? List<Map<String, String>>.from(_documentEntries) : null,
      socialNetworks: _socialEntries.isNotEmpty ? List<Map<String, String>>.from(_socialEntries) : null,
      messengers: _messengerEntries.isNotEmpty ? List<Map<String, String>>.from(_messengerEntries) : null,
    );
    final data = Provider.of<FamilyDataV001>(context, listen: false);
    if (widget.member != null) {
      data.updateMember(newMember);
    } else {
      data.addMember(newMember);
    }
    Navigator.of(context).pop();
  }

  Widget _buildEntryRow(
    List<Map<String, String>> entries,
    int index,
    List<String> types,
    void Function(void Function()) setStateCallback,
  ) {
    final entry = entries[index];
    // Each entry row contains a type dropdown, a value text field and a delete
    // button. Avoid wrapping the delete button in an Expanded widget because
    // that can cause horizontal overflow on narrow screens. The dropdown and
    // text field expand to fill available space, while the delete button
    // retains its natural size.
    return Row(
      // Using flex factors and fixed width for the delete button prevents
      // horizontal overflow on narrow screens. Each part of the row shares
      // available space according to its flex value. The delete button is
      // contained within a SizedBox to ensure it doesn't expand beyond its
      // intrinsic size, and the dropdown expands to fill its allotted space.
      children: [
        // Dropdown takes roughly 3/7 of the row width and expands to fill
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
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  ),
                )
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
        // Text field takes roughly 4/7 of the row width
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
        // Delete button wrapped in a SizedBox with a fixed width to avoid
        // taking up more space than necessary. This ensures the row fits
        // within the available width without overflow.
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
    // Use a ListView inside the Form so that the entire form scrolls
    // vertically when its content exceeds the screen height. This ensures
    // the Save button remains reachable even when many fields or entries
    // are added.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member != null ? 'Edit Member' : 'Add Member'),
        // Provide a save action in the app bar so the user can save the form
        // without needing to scroll to the bottom.  This ensures the save
        // functionality is always accessible, even when the form contents
        // extend beyond the visible screen area.
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        // Wrap the form fields in a SingleChildScrollView so the entire form
        // can scroll vertically when its contents grow beyond the screen. A
        // Column is used inside to lay out all the fields sequentially.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter a relationship'
                  : null,
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
            // Phone and email
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // Hobbies
            TextFormField(
              controller: _hobbiesController,
              decoration: const InputDecoration(labelText: 'Hobbies'),
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
                    _messengerEntries.add({'type': _messengerTypes.first, 'value': ''});
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
