import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import '../services/firestore_service.dart';

/// Provider for managing a list of friends stored remotely.
class FriendsData extends ChangeNotifier {
  FriendsData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<Friend> friends = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _firestore.fetchFriends(familyId);
      friends
        ..clear()
        ..addAll(fetched);
      _loaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFriend(Friend friend) async {
    await _firestore.upsertFriend(familyId, friend);
    friends.add(friend);
    notifyListeners();
  }

  Future<void> removeFriend(String id) async {
    await _firestore.deleteFriend(familyId, id);
    friends.removeWhere((friend) => friend.id == id);
    notifyListeners();
  }
}
