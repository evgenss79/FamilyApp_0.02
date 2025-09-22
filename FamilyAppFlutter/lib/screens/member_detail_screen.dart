import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'add_member_screen.dart';
import 'edit_documents_screen.dart';
import 'edit_hobbies_screen.dart';
import 'member_documents_screen.dart';
import 'member_hobbies_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
      builder: (context, data, _) {
        final member = data.memberById(memberId);
        if (member == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('memberTitle'))),
            body: Center(child: Text(context.tr('memberNotFound'))),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(member.name?.isNotEmpty == true
                ? member.name!
                : context.tr('memberTitle')),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: context.tr('editMember'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddMemberScreen(initialMember: member),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MemberAvatar(member: member),
              const SizedBox(height: 16),
              _InfoTile(
                title: context.tr('fieldRelationship'),
                value: member.relationship,
                icon: Icons.group,
              ),
              _InfoTile(
                title: context.tr('fieldPhone'),
                value: member.phone,
                icon: Icons.phone,
              ),
              _InfoTile(
                title: context.tr('fieldEmail'),
                value: member.email,
                icon: Icons.email,
              ),
              _InfoTile(
                title: context.tr('socialNetworksSection'),
                value: member.socialMedia,
                icon: Icons.share,
              ),
              _InfoTile(
                title: context.tr('documentsSummaryLabel'),
                value: member.documents,
                icon: Icons.description,
              ),
              if (member.birthday != null)
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: Text(context.tr('birthdayLabel')),
                  subtitle: Text(
                    context.loc.formatDate(member.birthday!, withTime: false),
                  ),
                ),
              if (member.hobbies?.isNotEmpty == true)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    leading: const Icon(Icons.local_activity),
                    title: Text(context.tr('fieldHobbies')),
                    subtitle: Text(member.hobbies!),
                  ),
                ),
              if (member.documentsList?.isNotEmpty == true)
                _EntriesSection(
                  title: context.tr('documentsSection'),
                  entries: member.documentsList!,
                  prefix: 'documentType',
                ),
              if (member.socialNetworks?.isNotEmpty == true)
                _EntriesSection(
                  title: context.tr('socialNetworksSection'),
                  entries: member.socialNetworks!,
                  prefix: 'socialNetwork',
                ),
              if (member.messengers?.isNotEmpty == true)
                _EntriesSection(
                  title: context.tr('messengersSection'),
                  entries: member.messengers!,
                  prefix: 'messenger',
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemberDocumentsScreen(member: member),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(context.tr('viewDocuments')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditDocumentsScreen(member: member),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_document),
                    label: Text(context.tr('editDocumentsAction')),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemberHobbiesScreen(member: member),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_esports),
                    label: Text(context.tr('viewHobbiesAction')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditHobbiesScreen(member: member),
                        ),
                      );
                    },
                    icon: const Icon(Icons.brush),
                    label: Text(context.tr('editHobbiesAction')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundImage:
            member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(
                member.name != null && member.name!.isNotEmpty
                    ? member.name!.substring(0, 1).toUpperCase()
                    : '?',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              )
            : null,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String? value;
  final IconData icon;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value!),
    );
  }
}

class _EntriesSection extends StatelessWidget {
  const _EntriesSection({
    required this.title,
    required this.entries,
    required this.prefix,
  });

  final String title;
  final List<Map<String, String>> entries;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in entries)
                  Chip(
                    label: Text(
                      '${context.tr("$prefix.${entry['type'] ?? 'other'}")}: ${entry['value'] ?? ''}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
