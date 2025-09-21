import 'package:flutter/foundation.dart';

import '../models/gallery_item.dart';

/// Provider that manages the family gallery of photos and videos.
///
/// The [GalleryData] provider stores a list of [GalleryItem] objects. In a
/// production version this provider would integrate with Firebase Storage
/// to upload images and store the resulting download URLs. For simplicity
/// this implementation only holds the list in memory.
class GalleryData extends ChangeNotifier {
  final List<GalleryItem> _items = [];

  List<GalleryItem> get items => List.unmodifiable(_items);

  /// Adds a new gallery item. Typically this method would be called after
  /// uploading an image to cloud storage and receiving a URL.
  void addItem(GalleryItem item) {
    _items.add(item);
    notifyListeners();
  }

  /// Removes a gallery item by id.
  void removeItem(String id) {
    _items.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Replaces the current list of items with [items].
  void setItems(List<GalleryItem> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }
}