import 'package:flutter/material.dart';

import '../models/family_member.dart';

/// Shows hobbies for a specific family member.
class MemberHobbiesScreen extends StatelessWidget {
  final FamilyMember member;
  const MemberHobbiesScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final hobbies = member.hobbies;
    return Scaffold(
      appBar: AppBar(
        title: Text('${member.name ?? 'Member'} hobbies'),
      ),
      body: hobbies == null || hobbies.isEmpty
          ? const Center(child: Text('No hobbies found.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                hobbies,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
    );
  }
}
