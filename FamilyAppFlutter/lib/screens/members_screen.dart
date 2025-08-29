import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/family_member.dart';
import 'add_member_screen.dart';

/// Displays a list of family members with extended details and allows
/// adding and removing members.  Uses [FamilyDataV001] to manage state.
class MembersScreenV001 extends StatelessWidget {
  const MembersScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(builder: (context, data, _) {
      final members = data.members;
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: members.isEmpty
            ? const Center(child: Text('No members added yet.'))
            : ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final List<String> details = [];
                  if (member.relationship.isNotEmpty) {
                    details.add(member.relationship);
                  }
                    // Include optional details if present and non-empty.
                  if (member.phone != null && member.phone!.isNotEmpty) {
                    details.add('Phone: ${member.phone}');
                  }
                  if (member.email != null && member.email!.isNotEmpty) {
                    details.add('Email: ${member.email}');
                  }
                  // Include structured social network entries if available
                  if (member.socialNetworks != null && member.socialNetworks!.isNotEmpty) {
                    for (final entry in member.socialNetworks!) {
                      final type = entry['type'] ?? '';
                      final value = entry['value'] ?? '';
                      if (value.isNotEmpty) {
                        details.add('$type: $value');
                      }
                    }
                  } else if (member.socialMedia != null && member.socialMedia!.isNotEmpty) {
                    // Fallback to legacy socialMedia string
                    details.add('Social: ${member.socialMedia}');
                  }
                  if (member.hobbies != null && member.hobbies!.isNotEmpty) {
                    details.add('Hobbies: ${member.hobbies}');
                  }
                  // Include structured documents if available
                  if (member.documentsList != null && member.documentsList!.isNotEmpty) {
                    for (final entry in member.documentsList!) {
                      final type = entry['type'] ?? '';
                      final value = entry['value'] ?? '';
                      if (value.isNotEmpty) {
                        details.add('$type: $value');
                      }
                    }
                  } else if (member.documents != null && member.documents!.isNotEmpty) {
                    details.add('Documents: ${member.documents}');
                  }
                  // Include messenger contacts
                  if (member.messengers != null && member.messengers!.isNotEmpty) {
                    for (final entry in member.messengers!) {
                      final type = entry['type'] ?? '';
                      final value = entry['value'] ?? '';
                      if (value.isNotEmpty) {
                        details.add('$type: $value');
                      }
                    }
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(member.name.isNotEmpty ? member.name[0] : '?'),
                    ),
                    title: Text(member.name),
                    subtitle: details.isNotEmpty ? Text(details.join('\n')) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddMemberScreenV001(member: member),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => data.removeMember(member),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Push the add-member form.  Do NOT use a `const` constructor here
            // because AddMemberScreenV001 contains mutable state (controllers),
            // which would produce a "not a constant expression" build error.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddMemberScreenV001(),
              ),
            );
          },
          // The add icon itself can remain constant.
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}