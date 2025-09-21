import 'package:flutter/foundation.dart';

import '../models/friend.dart';

/// Provider for managing a list of friends.  This example is
/// intentionally lightweight; methods could be expanded to include
/// editing or deleting friends as needed.
class FriendsData extends ChangeNotifier {
  final List<Friend> friends = [];

  void addFriend(Friend friend) {
    friends.add(friend);
    notifyListeners();
  }
}