import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';

/// Shows hobbies for a specific family member.
class MemberHobbiesScreen extends StatelessWidget {
  final FamilyMember member;
  const MemberHobbiesScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final hobbies = member.hobbies;
    final name = member.name?.isNotEmpty == true
        ? member.name!
        : context.tr('memberTitle');
    final title = context.loc.translateWithParams('memberHobbiesTitle', {
      'name': name,
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: hobbies == null || hobbies.isEmpty
          ? Center(child: Text(context.tr('noHobbiesLabel')))
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
