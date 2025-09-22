import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';

/// Displays a list of family members with quick access to details,
/// editing and deletion.  Each list item shows the member's initials,
/// relationship and key contact info.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
      builder: (context, data, _) {
        final List<FamilyMember> members = data.members;
        return Scaffold(
          appBar: AppBar(title: const Text('Family members')),
          body: members.isEmpty
              ? const Center(child: Text('No members added yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(_initials(member)),
                        ),
                        title: Text(member.name ?? 'No name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (member.relationship?.isNotEmpty == true)
                              Text(member.relationship!),
                            if (member.phone?.isNotEmpty == true)
                              Text(member.phone!),
                            if (member.email?.isNotEmpty == true)
                              Text(member.email!),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MemberDetailScreen(memberId: member.id),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddMemberScreen(initialMember: member),
                                  ),
                                );
                                break;
                              case 'delete':
                                _confirmDeletion(context, member);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: members.length,
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMemberScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  String _initials(FamilyMember member) {
    final name = member.name ?? '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return '?';
  }

  void _confirmDeletion(BuildContext context, FamilyMember member) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete member'),
          content: Text('Remove ${member.name ?? 'this member'} from the family?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<FamilyData>().removeMember(member);
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
