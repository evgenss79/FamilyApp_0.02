import 'package:flutter/foundation.dart';

import '../models/friend.dart';

/// Provider that manages the list of family friends (connections to other families).
///
/// This provider simply keeps a list of [Friend] objects in memory. In a future
/// iteration this list could be persisted to Hive or synchronized with
/// Firestore, similar to [FamilyDataV001].
class FriendsData extends ChangeNotifier {
  final List<Friend> _friends = [];

  List<Friend> get friends => List.unmodifiable(_friends);

  /// Adds a new friend connection to the list.
  void addFriend(Friend friend) {
    _friends.add(friend);
    notifyListeners();
  }

  /// Removes a friend connection by id. If the id is not found, nothing
  /// happens.
  void removeFriend(String id) {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  /// Replaces the current list of friends with [friends].
  void setFriends(List<Friend> friends) {
    _friends
      ..clear()
      ..addAll(friends);
    notifyListeners();
  }
}