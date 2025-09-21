import 'package:flutter/foundation.dart';

import '../models/gallery_item.dart';

/// Provider that manages photo gallery items.  This simplified
/// implementation supports adding items only.
class GalleryData extends ChangeNotifier {
  final List<GalleryItem> items = [];

  void addItem(GalleryItem item) {
    items.add(item);
    notifyListeners();
  }
}