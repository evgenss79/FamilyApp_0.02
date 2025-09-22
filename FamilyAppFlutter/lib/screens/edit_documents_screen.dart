import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Allows users to edit member documents.
class EditDocumentsScreen extends StatefulWidget {
  final FamilyMember member;
  const EditDocumentsScreen({super.key, required this.member});

  @override
  State<EditDocumentsScreen> createState() => _EditDocumentsScreenState();
}

class _EditDocumentsScreenState extends State<EditDocumentsScreen> {
  final _summaryController = TextEditingController();
  final List<_SelectEntry> _documents = [];

  @override
  void initState() {
    super.initState();
    _summaryController.text = widget.member.documents ?? '';
    final docs = widget.member.documentsList ?? const <Map<String, String>>[];
    if (docs.isEmpty) {
      _addDocument();
    } else {
      for (final doc in docs) {
        _documents.add(
          _SelectEntry(
            type: doc['type'] ?? 'other',
            initialValue: doc['value'] ?? doc['description'] ?? '',
          ),
        );
      }
    }
  }

  void _addDocument() {
    setState(() {
      _documents.add(_SelectEntry(type: _documentOptions.first));
    });
  }

  void _removeDocument(int index) {
    setState(() {
      if (_documents.length == 1) return;
      final removed = _documents.removeAt(index);
      removed.dispose();
      if (_documents.isEmpty) {
        _addDocument();
      }
    });
  }

  void _save() {
    final summary = _summaryController.text.trim();
    final docs = _documents
        .map((entry) => entry.toMap())
        .whereType<Map<String, String>>()
        .toList();
    context.read<FamilyData>().updateMemberDocuments(
          widget.member.id,
          summary: summary.isEmpty ? null : summary,
          documentsList: docs.isEmpty ? null : docs,
        );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    for (final doc in _documents) {
      doc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('editDocumentsAction'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: context.tr('documentsSummaryLabel'),
                  hintText: context.tr('documentsHint'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: doc.type ?? _documentOptions.first,
                              items: [
                                for (final option in _documentOptions)
                                  DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(context.tr('documentType.$option')),
                                  ),
                              ],
                              onChanged: (value) => setState(() => doc.type = value),
                              decoration: InputDecoration(
                                labelText: context.tr('documentTypeLabel'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: doc.value,
                              decoration: InputDecoration(
                                labelText: context.tr('documentValueLabel'),
                              ),
                              maxLines: 2,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => _removeDocument(index),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: context.tr('deleteAction'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _addDocument,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('addDocumentEntry')),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(context.tr('saveAction')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

const List<String> _documentOptions = <String>[
  'passport',
  'driverLicense',
  'birthCertificate',
  'insurancePolicy',
  'idCard',
  'other',
];
