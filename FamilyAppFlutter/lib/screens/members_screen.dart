import 'package:flutter/material.dart';
import '../models/family_member.dart';

/// Screen displaying a list of family members.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder list of members. Later this will come from a data store or backend.
    final List<FamilyMember> members = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: members.isEmpty
          ? const Center(child: Text('No members added yet.'))
          : ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(member.name),
                  subtitle: Text(member.relationship),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add member screen / show dialog.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
