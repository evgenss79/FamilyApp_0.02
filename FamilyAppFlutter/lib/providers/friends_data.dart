import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import '../services/firestore_service.dart';

class FriendsData extends ChangeNotifier {
  FriendsData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<Friend> friends = <Friend>[];

  StreamSubscription<List<Friend>>? _subscription;
  bool _initialized = false;
  bool _loading = false;

  bool get isLoading => _loading;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _loading = true;
    notifyListeners();

    final List<Friend> cached = await _firestore.loadCachedFriends(familyId);
    friends
      ..clear()
      ..addAll(cached);

    _subscription = _firestore.watchFriends(familyId).listen((List<Friend> data) {
      friends
        ..clear()
        ..addAll(data);
      notifyListeners();
    });

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> addFriend(Friend friend) async {
    friends.add(friend);
    notifyListeners();
    await _firestore.upsertFriend(familyId, friend);
  }

  Future<void> removeFriend(String id) async {
    friends.removeWhere((Friend friend) => friend.id == id);
    notifyListeners();
    await _firestore.deleteFriend(familyId, id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
