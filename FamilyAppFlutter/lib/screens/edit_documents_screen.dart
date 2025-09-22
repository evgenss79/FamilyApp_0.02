import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final List<_DocumentControllers> _documents = [];

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
          _DocumentControllers(
            title: TextEditingController(text: doc['title'] ?? doc['name'] ?? ''),
            value: TextEditingController(text: doc['description'] ?? doc['value'] ?? ''),
          ),
        );
      }
    }
  }

  void _addDocument() {
    setState(() {
      _documents.add(
        _DocumentControllers(
          title: TextEditingController(),
          value: TextEditingController(),
        ),
      );
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
      if (_documents.isEmpty) {
        _addDocument();
      }
    });
  }

  void _save() {
    final summary = _summaryController.text.trim();
    final docs = <Map<String, String>>[];
    for (final doc in _documents) {
      final title = doc.title.text.trim();
      final value = doc.value.text.trim();
      if (title.isEmpty && value.isEmpty) {
        continue;
      }
      docs.add({
        'title': title,
        'description': value,
      });
    }
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
      appBar: AppBar(title: Text('Edit documents – ${widget.member.name ?? ''}'.trim())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: 'General notes about documents',
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
                            TextField(
                              controller: doc.title,
                              decoration: const InputDecoration(labelText: 'Document title'),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: doc.value,
                              decoration: const InputDecoration(labelText: 'Details / description'),
                              maxLines: 2,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => _removeDocument(index),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove',
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
                    label: const Text('Add document'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
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

class _DocumentControllers {
  final TextEditingController title;
  final TextEditingController value;

  _DocumentControllers({required this.title, required this.value});

  void dispose() {
    title.dispose();
    value.dispose();
  }
}
