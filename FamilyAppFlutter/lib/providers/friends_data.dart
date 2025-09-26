import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import '../repositories/friends_repository.dart';
import '../services/sync_service.dart';

/// Provider for managing a list of friends backed by the sync-aware repository.
class FriendsData extends ChangeNotifier {
  FriendsData({
    required FriendsRepository repository,
    required SyncService syncService,
    required this.familyId,
  })  : _repository = repository,
        _syncService = syncService;

  final FriendsRepository _repository;
  final SyncService _syncService;
  final String familyId;

  final List<Friend> friends = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<Friend>>? _subscription;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      friends
        ..clear()
        ..addAll(await _repository.loadLocal(familyId));
      _subscription = _repository.watchLocal(familyId).listen(
        (List<Friend> updated) {
          friends
            ..clear()
            ..addAll(updated);
          notifyListeners();
        },
      );
      _loaded = true;
      await _syncService.flush();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFriend(Friend friend) async {
    await _repository.saveLocal(familyId, friend);
    await _syncService.flush();
  }

  Future<void> removeFriend(String id) async {
    await _repository.markDeleted(familyId, id);
    await _syncService.flush();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
