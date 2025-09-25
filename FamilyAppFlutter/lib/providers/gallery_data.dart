import 'package:flutter/foundation.dart';

import '../models/gallery_item.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Provider that manages photo gallery items with remote persistence.
class GalleryData extends ChangeNotifier {
  GalleryData({
    required FirestoreService firestore,
    required StorageService storage,
    required this.familyId,
  })  : _firestore = firestore,
        _storage = storage;

  final FirestoreService _firestore;
  final StorageService _storage;
  final String familyId;

  final List<GalleryItem> items = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _firestore.fetchGalleryItems(familyId);
      items
        ..clear()
        ..addAll(fetched);
      _loaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(GalleryItem item) async {
    await _firestore.upsertGalleryItem(familyId, item);
    items.add(item);
    notifyListeners();
  }

  Future<void> removeItem(String idOrUrl) async {
    final index = items.indexWhere(
      (item) => item.id == idOrUrl || item.url == idOrUrl,
    );
    if (index == -1) return;
    final item = items[index];
    await _firestore.deleteGalleryItem(familyId, item.id);
    if (item.storagePath != null) {
      await _storage.deleteByPath(item.storagePath!);
    } else if (item.url != null) {
      await _storage.deleteByUrl(item.url!);
    }
    items.removeAt(index);
    notifyListeners();
  }
}
