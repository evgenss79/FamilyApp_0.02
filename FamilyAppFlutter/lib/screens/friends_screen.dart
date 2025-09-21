import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../providers/friends_data.dart';

/// Screen showing the list of family friends (connections to other families).
///
/// Users can view existing friends and add a new friend by tapping the
/// floating action button. The addition dialog collects the friend’s
/// family name and an optional access level.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<void> _showAddFriendDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final accessController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Добавить друга'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название семьи',
                ),
              ),
              TextField(
                controller: accessController,
                decoration: const InputDecoration(
                  labelText: 'Уровень доступа (необязательно)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final access = accessController.text.trim();
                if (name.isNotEmpty) {
                  final friend = Friend(
                    familyName: name,
                    accessLevel: access.isEmpty ? null : access,
                  );
                  Provider.of<FriendsData>(context, listen: false)
                      .addFriend(friend);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsData = context.watch<FriendsData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Друзья семьи'),
      ),
      body: ListView.builder(
        itemCount: friendsData.friends.length,
        itemBuilder: (ctx, index) {
          final friend = friendsData.friends[index];
          return ListTile(
            leading: const Icon(Icons.group),
            title: Text(friend.familyName),
            subtitle: friend.accessLevel != null
                ? Text('Доступ: ${friend.accessLevel}')
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                friendsData.removeFriend(friend.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}