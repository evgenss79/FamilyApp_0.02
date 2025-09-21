import 'package:flutter/material.dart';

/// Allows users to edit member documents.  In this simplified version
/// no editing functionality is provided.
class EditDocumentsScreen extends StatelessWidget {
  const EditDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Documents')),
      body: const Center(child: Text('Document editing is not implemented.')),
    );
  }
}