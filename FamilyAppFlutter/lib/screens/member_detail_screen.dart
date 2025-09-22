import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
            appBar: AppBar(title: const Text('Member')),
            body: const Center(child: Text('Member not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(member.name?.isNotEmpty == true ? member.name! : 'Member'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit member',
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
              _InfoTile(
                title: 'Relationship',
                value: member.relationship,
                icon: Icons.group,
              ),
              _InfoTile(
                title: 'Phone',
                value: member.phone,
                icon: Icons.phone,
              ),
              _InfoTile(
                title: 'Email',
                value: member.email,
                icon: Icons.email,
              ),
              _InfoTile(
                title: 'Social networks',
                value: member.socialMedia,
                icon: Icons.share,
              ),
              _InfoTile(
                title: 'Avatar URL',
                value: member.avatarUrl,
                icon: Icons.image,
              ),
              if (member.birthday != null)
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: const Text('Birthday'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(member.birthday!)),
                ),
              if (member.hobbies?.isNotEmpty == true)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    leading: const Icon(Icons.local_activity),
                    title: const Text('Hobbies'),
                    subtitle: Text(member.hobbies!),
                  ),
                ),
              if (member.documents?.isNotEmpty == true)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Important documents'),
                    subtitle: Text(member.documents!),
                  ),
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
                    label: const Text('View documents'),
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
                    label: const Text('Edit documents'),
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
                    label: const Text('View hobbies'),
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
                    label: const Text('Edit hobbies'),
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
