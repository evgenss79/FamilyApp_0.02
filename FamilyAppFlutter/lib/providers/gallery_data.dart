import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../models/gallery_item.dart';
import '../repositories/gallery_repository.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// Provider that manages photo gallery items through the encrypted sync stack.
class GalleryData extends ChangeNotifier {
  GalleryData({
    required GalleryRepository repository,
    required StorageService storage,
    required SyncService syncService,
    required this.familyId,
  })  : _repository = repository,
        _storage = storage,
        _syncService = syncService;

  final GalleryRepository _repository;
  final StorageService _storage;
  final SyncService _syncService;
  final String familyId;

  final List<GalleryItem> items = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<GalleryItem>>? _subscription;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      items
        ..clear()
        ..addAll(await _repository.loadLocal(familyId));
      _subscription = _repository.watchLocal(familyId).listen(
        (List<GalleryItem> updated) {
          items
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

  Future<void> addItem(GalleryItem item) async {
    await _repository.saveLocal(familyId, item);
    await _syncService.flush();
  }

  Future<void> removeItem({
    required GalleryItem item,
    required FamilyMember? requester,
  }) async {
    final String? requesterId = requester?.id;
    final bool isAdmin = requester?.isAdmin ?? false;
    // SECURITY: enforce family-scoped ACL before removing gallery entries.
    if (requesterId == null || requester?.familyId != familyId) {
      throw StateError('requester-not-authorized');
    }
    if (!isAdmin && item.ownerId != null && item.ownerId != requesterId) {
      throw StateError('requester-not-owner');
    }
    if (item.familyId != null && item.familyId != familyId) {
      throw StateError('item-family-mismatch');
    }

    await _repository.markDeleted(familyId, item.id);
    await _syncService.flush();
    final String? storagePath = item.storagePath;
    if (storagePath != null && storagePath.startsWith('families/$familyId/')) {
      await _storage.deleteByPath(storagePath);
    } else if (item.url != null) {
      await _storage.deleteByUrl(item.url!);
    }
  }

  Future<void> refresh() async {
    await _repository.pullRemote(familyId);
    final List<GalleryItem> latest = await _repository.loadLocal(familyId);
    items
      ..clear()
      ..addAll(latest);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
