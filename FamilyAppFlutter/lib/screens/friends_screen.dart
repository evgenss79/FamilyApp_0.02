import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friends_data.dart';
import '../models/friend.dart';

/// Shows a list of friends.  Friends can be added elsewhere in the
/// application; this screen simply displays them.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Consumer<FriendsData>(
        builder: (context, data, _) {
          if (data.friends.isEmpty) {
            return const Center(child: Text('No friends added.'));
          }
          return ListView.builder(
            itemCount: data.friends.length,
            itemBuilder: (context, index) {
              final Friend friend = data.friends[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(friend.name ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}