import 'package:flutter/foundation.dart';

import '../models/schedule_item.dart';

/// Provider for managing schedule items.  Items can be added and
/// listeners are notified of changes.  Additional methods for
/// filtering or updating items could be added later.
class ScheduleData extends ChangeNotifier {
  final List<ScheduleItem> items = [];

  void addItem(ScheduleItem item) {
    items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
