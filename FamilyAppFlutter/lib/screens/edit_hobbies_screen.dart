import 'package:flutter/material.dart';

/// Allows users to edit a member's hobbies.  This stub screen
/// currently shows a placeholder message.
class EditHobbiesScreen extends StatelessWidget {
  const EditHobbiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Hobbies')),
      body: const Center(child: Text('Hobby editing is not implemented.')),
    );
  }
}