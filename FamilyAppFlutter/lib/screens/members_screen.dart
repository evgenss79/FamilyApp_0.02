import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/family_member.dart';
import 'add_member_screen.dart';

class MembersScreenV001 extends StatelessWidget {
  const MembersScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(builder: (context, data, _) {
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
                  if (member.phone != null && member.phone!.isNotEmpty) {
                    details.add('Phone: ${member.phone}');
                  }
                  if (member.email != null && member.email!.isNotEmpty) {
                    details.add('Email: ${member.email}');
                  }
                  if (member.socialMedia != null && member.socialMedia!.isNotEmpty) {
                    details.add('Social: ${member.socialMedia}');
                  }
                  if (member.hobbies != null && member.hobbies!.isNotEmpty) {
                    details.add('Hobbies: ${member.hobbies}');
                  }
                  if (member.documents != null && member.documents!.isNotEmpty) {
                    details.add('Documents: ${member.documents}');
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(member.name.isNotEmpty ? member.name[0] : '?'),
                    ),
                    title: Text(member.name),
                    subtitle:
                        details.isNotEmpty ? Text(details.join('\n')) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => data.removeMember(member.id),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddMemberScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
