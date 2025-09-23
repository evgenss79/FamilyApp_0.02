import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/friend.dart';
import '../providers/friends_data.dart';
import 'add_friend_screen.dart';

/// Shows a list of friends with the ability to add and remove entries.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('friends'))),
      body: Consumer<FriendsData>(
        builder: (context, data, _) {
          if (data.isLoading && data.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.friends.isEmpty) {
            return Center(child: Text(context.tr('noFriendsLabel')));
          }
          return ListView.separated(
            itemCount: data.friends.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final Friend friend = data.friends[index];
              final String displayName = friend.name.trim().isEmpty
                  ? context.tr('noNameLabel')
                  : friend.name;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(displayName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await context.read<FriendsData>().removeFriend(friend.id);
                  },
                  tooltip: context.tr('deleteAction'),
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
        tooltip: context.tr('addFriendTitle'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
