import 'package:flutter/material.dart';

/// Shows hobbies for a specific family member.  Currently this
/// simplified screen displays a placeholder message.
class MemberHobbiesScreen extends StatelessWidget {
  const MemberHobbiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Hobbies')),
      body: const Center(child: Text('No hobbies found.')),
    );
  }
}