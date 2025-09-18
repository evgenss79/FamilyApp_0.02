import 'package:flutter/material.dart';

class MemberDocumentsScreen extends StatelessWidget {
  static const routeName = '/member-documents';

  const MemberDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> documents =
        (ModalRoute.of(context)?.settings.arguments as List<String>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: documents.isEmpty
          ? const Center(
              child: Text('No documents available.'),
            )
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (ctx, index) {
                final doc = documents[index];
                return ListTile(
                  title: Text(doc),
                  onTap: () {
                    // TODO: Implement document viewer or download
                  },
                );
              },
            ),
    );
  }
}
