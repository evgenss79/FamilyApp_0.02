import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';

/// Displays a list of family members with quick access to details,
/// editing and deletion.  Each list item shows the member's initials,
/// relationship and key contact info.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  static const String routeName = 'MembersScreen';

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
      builder: (context, data, _) {
        final members = data.members;
        final isLoading = data.isLoading && members.isEmpty;
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('members'))),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : members.isEmpty
                  ? Center(child: Text(context.tr('noMembersLabel')))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: member.avatarUrl != null
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? Text(_initials(member))
                                  : null,
                            ),
                            title: Text(member.name ?? context.tr('noNameLabel')),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (member.relationship?.isNotEmpty == true)
                                  Text(member.relationship!),
                                if (member.phone?.isNotEmpty == true)
                                  Text(
                                    '${context.tr('fieldPhone')}: ${member.phone}',
                                  ),
                                if (member.email?.isNotEmpty == true)
                                  Text(
                                    '${context.tr('fieldEmail')}: ${member.email}',
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MemberDetailScreen(memberId: member.id),
                                  settings: RouteSettings(
                                    name: MemberDetailScreen.routeName,
                                  ),
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
                                        settings: const RouteSettings(
                                          name: AddMemberScreen.routeName,
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'delete':
                                    _confirmDeletion(context, member);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(context.tr('editAction')),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: Text(context.tr('deleteAction')),
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
                MaterialPageRoute(
                  builder: (_) => const AddMemberScreen(),
                  settings: const RouteSettings(
                    name: AddMemberScreen.routeName,
                  ),
                ),
              );
            },
            tooltip: context.tr('addMember'),
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
          title: Text(context.tr('deleteMemberDialogTitle')),
          content: Text(
            ctx.loc.confirmRemoveMember(
              member.name ?? ctx.tr('memberFallback'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.tr('cancelAction')),
            ),
            FilledButton(
              onPressed: () async {
                await context.read<FamilyData>().removeMember(member);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              child: Text(context.tr('deleteAction')),
            ),
          ],
        );
      },
    );
  }
}
