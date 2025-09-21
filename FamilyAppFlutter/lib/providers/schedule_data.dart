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

  /// Returns schedule items filtered by the optional [day] and [memberId].
  ///
  /// If [day] is provided, only items whose start date matches the provided
  /// date (ignoring the time component) will be returned. If [memberId] is
  /// provided, only items whose list of member IDs contains the given
  /// identifier will be returned. When both filters are provided, items must
  /// satisfy both conditions to be included in the result.
  List<ScheduleItem> getItemsFiltered({DateTime? day, String? memberId}) {
    // Normalize the day to ignore the time portion.
    final normalizedDay = day == null
        ? null
        : DateTime(day.year, day.month, day.day);
    return _items.where((it) {
      // Filter by member. If no memberId filter is provided or the schedule
      // item has no memberIds specified, consider the check passed.
      final memberOk = memberId == null ||
          (it.memberIds == null || it.memberIds!.isEmpty)
              ? true
              : it.memberIds!.contains(memberId);
      if (!memberOk) return false;
      // Filter by date. Only match against the startDateTime's date portion.
      if (normalizedDay != null) {
        final start = it.startDateTime;
        final itemDay = DateTime(start.year, start.month, start.day);
        if (itemDay != normalizedDay) return false;
      }
      return true;
    }).toList();
  }
}