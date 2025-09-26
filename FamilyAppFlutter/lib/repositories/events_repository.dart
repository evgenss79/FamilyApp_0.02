import '../models/event.dart';
import 'base_firestore_repository.dart';

class EventsRepository extends BaseFirestoreRepository<Event> {
  EventsRepository()
      : super(
          collectionName: 'events',
          fromMap: Event.fromMap,
          toMap: (Event event) => event.toMap(),
          idSelector: (Event event) => event.id,
          sorter: (Event a, Event b) => a.startDateTime.compareTo(b.startDateTime),
        );
}

