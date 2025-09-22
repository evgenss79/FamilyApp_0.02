import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../providers/friends_data.dart';
import 'add_friend_screen.dart';

/// Shows a list of friends with the ability to add and remove entries.
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
          return ListView.separated(
            itemCount: data.friends.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final Friend friend = data.friends[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(friend.name ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    final id = friend.id;
                    if (id != null) {
                      context.read<FriendsData>().removeFriend(id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddFriendScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
