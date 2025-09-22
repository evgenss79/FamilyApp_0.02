import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';

/// Shows documents for a specific family member.
class MemberDocumentsScreen extends StatelessWidget {
  final FamilyMember member;
  const MemberDocumentsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final docs = member.documentsList ?? const <Map<String, String>>[];
    final hasSummary = member.documents?.isNotEmpty == true;
    final title = context.loc.translateWithParams(
      'memberDocumentsTitle',
      {
        'name': member.name?.isNotEmpty == true
            ? member.name!
            : context.tr('memberTitle'),
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: (docs.isEmpty && !hasSummary)
          ? Center(child: Text(context.tr('noDocumentsLabel')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (hasSummary)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(context.tr('documentsSummaryLabel')),
                      subtitle: Text(member.documents!),
                    ),
                  ),
                for (final doc in docs)
                  _DocumentCard(
                    document: doc,
                    prefix: 'documentType',
                  ),
              ],
            ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, String> document;
  final String prefix;
  const _DocumentCard({required this.document, required this.prefix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeKey = document['type'] ?? 'other';
    final title =
        '${context.tr("$prefix.$typeKey")}: ${document['value'] ?? document['description'] ?? ''}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
