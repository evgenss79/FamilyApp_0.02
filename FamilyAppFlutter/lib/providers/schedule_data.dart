import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';
import '../repositories/schedule_repository.dart';
import '../services/sync_service.dart';

/// Provider for managing schedule items backed by the sync-aware repositories.
class ScheduleData extends ChangeNotifier {
  ScheduleData({
    required ScheduleRepository repository,
    required SyncService syncService,
    required this.familyId,
  })  : _repository = repository,
        _syncService = syncService;

  final ScheduleRepository _repository;
  final SyncService _syncService;
  final String familyId;

  final List<ScheduleItem> items = [];

  bool _loaded = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<ScheduleItem>>? _subscription;

  Future<void> load() async {
    if (_loaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      items
        ..clear()
        ..addAll(await _repository.loadLocal(familyId));
      _subscription = _repository.watchLocal(familyId).listen(
        (List<ScheduleItem> updated) {
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

  Future<void> addItem(ScheduleItem item) async {
    await _repository.saveLocal(familyId, item);
    await _syncService.flush();
  }

  Future<void> removeItem(String id) async {
    await _repository.markDeleted(familyId, id);
    await _syncService.flush();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
