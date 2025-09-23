import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';
import '../services/firestore_service.dart';

class ScheduleData extends ChangeNotifier {
  ScheduleData({required FirestoreService firestore, required this.familyId})
      : _firestore = firestore;

  final FirestoreService _firestore;
  final String familyId;

  final List<ScheduleItem> items = <ScheduleItem>[];

  StreamSubscription<List<ScheduleItem>>? _subscription;
  bool _initialized = false;
  bool _loading = false;

  bool get isLoading => _loading;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _loading = true;
    notifyListeners();

    final List<ScheduleItem> cached =
        await _firestore.loadCachedSchedule(familyId);
    items
      ..clear()
      ..addAll(cached);

    _subscription = _firestore.watchSchedule(familyId).listen((List<ScheduleItem> data) {
      items
        ..clear()
        ..addAll(data);
      items.sort((ScheduleItem a, ScheduleItem b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
    });

    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> addItem(ScheduleItem item) async {
    items.add(item);
    notifyListeners();
    await _firestore.createScheduleItem(familyId, item);
  }

  Future<void> removeItem(String id) async {
    items.removeWhere((ScheduleItem element) => element.id == id);
    notifyListeners();
    await _firestore.deleteScheduleItem(familyId, id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
