import 'package:flutter/material.dart';

import '../models/family_member.dart';

/// Shows documents for a specific family member.
class MemberDocumentsScreen extends StatelessWidget {
  final FamilyMember member;
  const MemberDocumentsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final docs = member.documentsList ?? const <Map<String, String>>[];
    final hasSummary = member.documents?.isNotEmpty == true;
    return Scaffold(
      appBar: AppBar(
        title: Text('${member.name ?? 'Member'} documents'),
      ),
      body: (docs.isEmpty && !hasSummary)
          ? const Center(child: Text('No documents available.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (hasSummary)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Summary'),
                      subtitle: Text(member.documents!),
                    ),
                  ),
                for (final doc in docs) _DocumentCard(document: doc),
              ],
            ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, String> document;
  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = document['title'] ?? document['name'] ?? 'Document';
    final cleaned = Map<String, String>.from(document);
    cleaned.remove('title');
    cleaned.remove('name');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (cleaned.isEmpty)
              const Text('No additional information')
            else
              ...cleaned.entries
                  .where((entry) => entry.value.trim().isNotEmpty)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      )),
          ],
        ),
      ),
    );
  }
}
