import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';
import 'add_member_screen.dart';

/// Displays a list of family members.  Each list item shows the
/// member's name, optional relationship, and a delete button.  A
/// floating action button allows users to add new members.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
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
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (member.name ?? '').isNotEmpty
                              ? member.name![0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(member.name ?? 'No name'),
                      subtitle: Text(member.relationship ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          data.members.removeAt(index);
                          
                        },
                      ),
                    );
                  },
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
}
