import '../models/schedule_item.dart';
import 'base_firestore_repository.dart';

class ScheduleRepository extends BaseFirestoreRepository<ScheduleItem> {
  ScheduleRepository()
      : super(
          collectionName: 'scheduleItems',
          fromMap: ScheduleItem.fromMap,
          toMap: (ScheduleItem item) => item.toMap(),
          idSelector: (ScheduleItem item) => item.id,
          sorter: (ScheduleItem a, ScheduleItem b) =>
              a.dateTime.compareTo(b.dateTime),
        );
}

