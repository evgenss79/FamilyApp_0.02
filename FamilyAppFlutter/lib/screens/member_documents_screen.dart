import 'package:flutter/material.dart';

/// Shows documents for a specific family member.  This simplified
/// version only displays a placeholder message.
class MemberDocumentsScreen extends StatelessWidget {
  const MemberDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Documents')),
      body: const Center(child: Text('No documents available.')),
    );
  }
}