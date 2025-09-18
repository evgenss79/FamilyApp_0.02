import 'package:flutter/material.dart';

class MemberHobbiesScreen extends StatelessWidget {
  static const routeName = '/member-hobbies';

  const MemberHobbiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> hobbies =
        (ModalRoute.of(context)?.settings.arguments as List<String>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hobbies'),
      ),
      body: hobbies.isEmpty
          ? const Center(
              child: Text('No hobbies available.'),
            )
          : ListView.builder(
              itemCount: hobbies.length,
              itemBuilder: (ctx, index) {
                final hobby = hobbies[index];
                return ListTile(
                  title: Text(hobby),
                );
              },
            ),
    );
  }
}
