import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Allows users to edit a member's hobbies.
class EditHobbiesScreen extends StatefulWidget {
  final FamilyMember member;
  const EditHobbiesScreen({super.key, required this.member});

  @override
  State<EditHobbiesScreen> createState() => _EditHobbiesScreenState();
}

class _EditHobbiesScreenState extends State<EditHobbiesScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.member.hobbies ?? '');
  }

  void _save() {
    final hobbies = _controller.text.trim();
    context
        .read<FamilyData>()
        .updateMemberHobbies(widget.member.id, hobbies.isEmpty ? null : hobbies);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberName = widget.member.name?.isNotEmpty == true
        ? widget.member.name!
        : context.tr('memberTitle');
    final title = '${context.tr('editHobbiesAction')} – $memberName';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: context.tr('fieldHobbies'),
                hintText: context.tr('hobbiesHint'),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(context.tr('saveAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
