import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/gallery_item.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

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

  final List<GalleryItem> items = <GalleryItem>[];

  StreamSubscription<List<GalleryItem>>? _subscription;
  bool _initialized = false;
  bool _loading = false;

  bool get isLoading => _loading;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _loading = true;
    notifyListeners();

    final List<GalleryItem> cached =
        await _firestore.loadCachedGallery(familyId);
    items
      ..clear()
      ..addAll(cached);

    _subscription = _firestore.watchGallery(familyId).listen((List<GalleryItem> data) {
      items
        ..clear()
        ..addAll(data);
      notifyListeners();
    });

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> addItem(GalleryItem item) async {
    items.add(item);
    notifyListeners();
    await _firestore.upsertGalleryItem(familyId, item);
  }

  Future<void> removeItem(String idOrUrl) async {
    final int index = items.indexWhere(
      (GalleryItem item) => item.id == idOrUrl || item.url == idOrUrl,
    );
    if (index == -1) {
      return;
    }
    final GalleryItem item = items[index];
    items.removeAt(index);
    notifyListeners();

    await _firestore.deleteGalleryItem(familyId, item.id);
    if (item.storagePath != null && item.storagePath!.isNotEmpty) {
      await _storage.deleteByPath(item.storagePath!);
    } else if (item.url != null && item.url!.isNotEmpty) {
      await _storage.deleteByUrl(item.url!);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
