import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';
import '../services/firestore_service.dart';

/// Provider for managing schedule items backed by Firestore.
class ScheduleData extends ChangeNotifier {
  ScheduleData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<ScheduleItem> items = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _firestore.fetchScheduleItems(familyId);
      items
        ..clear()
        ..addAll(fetched);
      _loaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(ScheduleItem item) async {
    await _firestore.upsertScheduleItem(familyId, item);
    items.add(item);
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    await _firestore.deleteScheduleItem(familyId, id);
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
