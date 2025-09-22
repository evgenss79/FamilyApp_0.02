import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Placeholder for a screen that would host a cloud-based call.
/// Displays a message indicating that no call is active.
class CloudCallScreen extends StatelessWidget {
  const CloudCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('cloudCall'))),
      body: Center(child: Text(context.tr('noActiveCallLabel'))),
    );
  }
}
