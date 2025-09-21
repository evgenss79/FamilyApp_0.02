import 'package:flutter/material.dart';

/// Placeholder for a screen that would host a cloud-based call.
/// Displays a message indicating that no call is active.
class CloudCallScreen extends StatelessWidget {
  const CloudCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Call')),
      body: const Center(child: Text('No active call.')),
    );
  }
}