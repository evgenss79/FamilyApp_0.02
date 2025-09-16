import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';
import '../services/storage_service.dart';

/// Provider that manages schedule items for the family.
class ScheduleDataV001 extends ChangeNotifier {
  final List<ScheduleItem> _items = [];

  List<ScheduleItem> get items => _items;

  /// Loads schedule items from local encrypted storage.
  Future<void> loadFromStorage() async {
    _items
      ..clear()
      ..addAll(StorageServiceV001.loadScheduleItems());
    notifyListeners();
  }

  /// Adds a new schedule item and persists changes.
  void addItem(ScheduleItem item) {
    _items.add(item);
    StorageServiceV001.saveScheduleItems(_items);
    notifyListeners();
  }

  /// Updates an existing schedule item.
  void updateItem(ScheduleItem item) {
    final index = _items.indexWhere((x) => x.id == item.id);
    if (index != -1) {
      _items[index] = item;
      StorageServiceV001.saveScheduleItems(_items);
      notifyListeners();
    }
  }

  /// Removes a schedule item.
  void removeItem(ScheduleItem item) {
    _items.removeWhere((x) => x.id == item.id);
    StorageServiceV001.saveScheduleItems(_items);
    notifyListeners();
  }

  /// Replaces the entire list of schedule items.
  void setItems(List<ScheduleItem> items) {
    _items
      ..clear()
      ..addAll(items);
    StorageServiceV001.saveScheduleItems(_items);
    notifyListeners();
  }
}