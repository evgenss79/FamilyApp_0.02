import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';
import '../services/storage_service.dart';

/// Provider for managing a list of [ScheduleItem]s.
///
/// This class encapsulates loading schedule data from persistent storage,
/// notifying listeners when the list changes, and saving changes back to
/// storage. It follows the same pattern as [FamilyDataV001] for
/// consistency.
class ScheduleDataV001 extends ChangeNotifier {
  final List<ScheduleItem> _items = [];

  /// Returns the current list of schedule items.
  List<ScheduleItem> get items => _items;

  /// Loads schedule items from storage. Clears any existing items first.
  Future<void> loadFromStorage() async {
    _items
      ..clear()
      ..addAll(StorageServiceV001.loadScheduleItems());
    notifyListeners();
  }

  /// Adds a new schedule item and persists the updated list.
  void addItem(ScheduleItem item) {
    _items.add(item);
    StorageServiceV001.saveScheduleItems(_items);
    notifyListeners();
  }

  /// Updates an existing schedule item. Does nothing if the item is not found.
  void updateItem(ScheduleItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      StorageServiceV001.saveScheduleItems(_items);
      notifyListeners();
    }
  }

  /// Removes a schedule item from the list and persists the change.
  void removeItem(ScheduleItem item) {
    _items.removeWhere((i) => i.id == item.id);
    StorageServiceV001.saveScheduleItems(_items);
    notifyListeners();
  }
}