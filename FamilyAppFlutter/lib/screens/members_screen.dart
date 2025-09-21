import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import 'add_member_screen.dart';
import 'member_documents_screen.dart';
import 'member_hobbies_screen.dart';
import 'edit_documents_screen.dart';
import 'edit_hobbies_screen.dart';


/// Displays a list of family members with extended details and allows
/// adding and removing members. Uses [FamilyDataV001] to manage state.
class MembersScreenV001 extends StatelessWidget {
  const MembersScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, _) {
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

                    // Relationship
                    if (member.relationship.isNotEmpty) {
                      details.add(member.relationship);
                    }

                    // Phone
                    if (member.phone != null && member.phone!.isNotEmpty) {
                      details.add('Phone: ${member.phone}');
                    }

                    // Email
                    if (member.email != null && member.email!.isNotEmpty) {
                      details.add('Email: ${member.email}');
                    }

                    // Structured social networks if available
                    if (member.socialNetworks != null &&
                        member.socialNetworks!.isNotEmpty) {
                      for (final entry in member.socialNetworks!) {
                        final type = entry['type'] ?? '';
                        final value = entry['value'] ?? '';
                        if (value.isNotEmpty) {
                          details.add('$type: $value');
                        }
                      }
                    } else if (member.socialMedia != null &&
                        member.socialMedia!.isNotEmpty) {
                      // Fallback to legacy socialMedia string
                      details.add('Social: ${member.socialMedia}');
                    }

                    // Hobbies
                    if (member.hobbies != null && member.hobbies!.isNotEmpty) {
                      if (member.hobbies is List<String>) {
                        details.add('Hobbies: ${member.hobbies!.join(', ')}');
                      } else {
                        details.add('Hobbies: ${member.hobbies}');
                      }
                    }

                    // Structured documents if available
                    if (member.documentsList != null &&
                        member.documentsList!.isNotEmpty) {
                      for (final entry in member.documentsList!) {
                        final type = entry['type'] ?? '';
                        final value = entry['value'] ?? '';
                        final formatted =
                            type.toString().isNotEmpty ? '$type: $value' : value.toString();
                        if (formatted.isNotEmpty) {
                          details.add(formatted);
                        }
                      }
                    } else if (member.documents != null &&
                        member.documents!.isNotEmpty) {
                      details.add('Documents: ${member.documents}');
                    }

                    // Messenger contacts
                    if (member.messengers != null &&
                        member.messengers!.isNotEmpty) {
                      for (final entry in member.messengers!) {
                        final type = entry['type'] ?? '';
                        final value = entry['value'] ?? '';
                        if (value.isNotEmpty) {
                          details.add('$type: $value');
                        }
                      }
                    }

                    // Calculate earned points by summing points from completed tasks
                    final int points = data.tasks
                        .where((task) =>
                            task.assignedMemberId == member.id &&
                            task.status.toLowerCase() == 'completed')
                        .fold<int>(0, (sum, task) => sum + task.points);
                    if (points > 0) {
                      details.add('Points: $points');
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (member.avatarUrl != null &&
                                member.avatarUrl!.isNotEmpty)
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: (member.avatarUrl == null ||
                                member.avatarUrl!.isEmpty)
                            ? Text(member.name.isNotEmpty
                                ? member.name[0]
                                : '?')
                            : null,
                      ),
                      title: Text(member.name),
                      subtitle:
                          details.isNotEmpty ? Text(details.join('\n')) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Documents icon
                          if ((member.documentsList != null &&
                                  member.documentsList!.isNotEmpty) ||
                              (member.documents != null &&
                                  member.documents!.isNotEmpty))
                            IconButton(
             
                              icon: const Icon(Icons.description),
                              onLongPress: () async {
                                // Build list of documents (same logic as onPressed)
                                List<String> docs;
                                if (member.documentsList != null &&
                                    member.documentsList!.isNotEmpty) {
                                  docs = member.documentsList!.map<String>((entry) {
                                    final type = entry['type'] ?? '';
                                    final value = entry['value'] ?? '';
                                    return type.toString().isNotEmpty
                                        ? '$type: $value'
                                        : value.toString();
                                  }).toList();
                                } else {
                                  docs = member.documents!
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                                // Open edit screen and await updated docs
                                final updatedDocs = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditDocumentsScreen(initialDocs: docs),
                                  ),
                                );
                                if (updatedDocs != null) {
                                  data.updateDocuments(member.id, List<String>.from(updatedDocs));
                                }
                              },
                              onPressed: () {
                                List<String> docs;
                                if (member.documentsList != null &&
                                    member.documentsList!.isNotEmpty) {
                                  docs = member.documentsList!.map<String>((entry) {
                                    final type = entry['type'] ?? '';
                                    final value = entry['value'] ?? '';
                                    return type.toString().isNotEmpty
                                        ? '$type: $value'
                                        : value.toString();
                                  }).toList();
                                } else {
                                  docs = member.documents!
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MemberDocumentsScreen(),
                                    settings:
                                        RouteSettings(arguments: docs),
                                  ),
                                );
                              },
                            ),
                          // Hobbies icon
                          if (member.hobbies != null &&
                              member.hobbies!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.star),
                              onLongPress: () async {
                                // Build list of hobbies (same logic as onPressed)
                                List<String> hobbiesList;
                                if (member.hobbies is List<String>) {
                                  hobbiesList =
                                      List<String>.from(member.hobbies as List);
                                } else {
                                  hobbiesList = member.hobbies
                                      .toString()
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                                // Open edit screen and await updated hobbies
                                final updatedHobbies = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditHobbiesScreen(initialHobbies: hobbiesList),
                                  ),
                                );
                                if (updatedHobbies != null) {
                                  data.updateHobbies(member.id, List<String>.from(updatedHobbies));
                                }
                              },
                              onPressed: () {
             
                                List<String> hobbiesList;
                                if (member.hobbies is List<String>) {
                                  hobbiesList =
                                      List<String>.from(member.hobbies as List);
                                } else {
                                  hobbiesList = member.hobbies
                                      .toString()
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MemberHobbiesScreen(),
                                    settings:
                                        RouteSettings(arguments: hobbiesList),
                                  ),
                                );
                              },
                            ),
                          // Edit icon
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddMemberScreenV001(member: member),
                                ),
                              );
                            },
                          ),
                          // Delete icon
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMemberScreenV001(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
